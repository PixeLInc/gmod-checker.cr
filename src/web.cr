require "raze"
require "kilt/slang"
require "http/client"
require "./steam.cr"
require "./mappings.cr"

module Steam
  get "/" do |ctx|
    render("views/index.slang")
  end

  def self.run_check(steam_ids)
    # results = client.sharing_info(steam_ids)
    # results = Client.send_request(steam_ids)

    # p results

    # results
    [] of Steam::Responses::SteamUser
  end

  record(
    InvalidID,
    steam_id : String?,
    invalid : Bool = true
  )

  # For the web api version
  # TODO: Do this later, websocket is priority and the api equiv for other users can be done later.
  get "/check" do |ctx|
    sids = ctx.query["steamids"]?

    ctx.halt({"error": "Missing steamids param"}.to_json, 400) if !sids || sids.empty?
    ctx.response.content_type = "application/json"

    if sids.is_a?(String)
      sids = sids.split(',').map do |e|
        begin
          Steam::ID.new(e)
        rescue Steam::ID::InvalidIDException
          InvalidID.new(e)
        end
      end

      results = [] of Steam::Responses::SteamUser | InvalidID
      valid_ids, invalid_ids = sids.partition { |steam_id| steam_id.is_a?(Steam::ID) }
      results = self.run_check(valid_ids)
      results = invalid_ids

      {"type" => "batch_result", "results" => "test"}.to_json
    end
  end

  # For websocket checking
  post "/check" do |ctx|
    # return a randomly generated nonce that must be verified upon connection.
  end

  ws "/ws" do |ws, ctx|
    puts "We got a new socket connection!"

    # Wait for a nonce, if none is recieved within 30 seconds or it's invalid, terminate the connection.

    ws.on_message do |msg|
      puts "New Message! #{msg}"
      # Just send some random data back for now.

      ws.send({"type" => "result", "title" => "REEEEEE", "desc" => "r e e e e e"}.to_json)
    end
  end
end

Raze.run
