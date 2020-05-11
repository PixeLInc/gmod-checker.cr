class Handlers::SocketHandler
  include HTTP::Handler

  def initialize
    @ws_handler = HTTP::WebSocketHandler.new(&->ws(HTTP::WebSocket, HTTP::Server::Context))
  end

  def serialize(nonce, result)
    JSON.build do |builder|
      builder.object do
        builder.field("nonce", nonce.to_s)
        builder.string "type"
        if result.is_a?(Job::PlayerResult)
          builder.string "player_result"
          builder.string "data"
          result.to_json(builder)
        elsif result.is_a?(Job::BatchPlayers)
          builder.string "batch_players"
          builder.string "data"
          result.to_json(builder)
        elsif result.is_a?(Job::Error)
          builder.string "error"
          builder.field("message", result.message)
          builder.field("data", result.id)
        elsif result.is_a?(Exception)
          builder.string "error"
          builder.field("message", result.message)
        end
      end
    end
  end


  def ws(socket : HTTP::WebSocket, context : HTTP::Server::Context)
    socket.on_message do |message|
      nonce = JobController::Nonce.from_json(message, "nonce")
      JobController.dispatch(nonce) do |result|
        payload = serialize(nonce, result)
        socket.send(payload)
      end
    rescue ex : JSON::ParseException | KeyError
      payload = serialize(nonce, ex)
      socket.send(payload)
    end
  end

  def call(context : HTTP::Server::Context)
    case context.request.path
    when "/api/relay" then @ws_handler.call(context)
    else
      call_next(context)
    end
  end
end