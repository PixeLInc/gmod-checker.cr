require "kilt/slang"

class Handlers::WebRouter
  include HTTP::Handler

  def initialize
    @logger = Log.for("web")
    @client = Steam::Client.new(ENV["STEAM_API_KEY"], @logger.for("Steam"))

    JobController.logger = @logger.for("JobController")
  end

  def handle_check(context : HTTP::Server::Context)
    if context.request.method != "POST"
      context.response.respond_with_status(:method_not_allowed)
      return
    end

    @logger.info { "Handling check endpoint!" }
    raw_ids = context.request.query_params["steamids"].split(',')

    # ctx.halt({"error": ""}, 400) if !raw_ids || raw_ids == ""

    nonce = JobController.create(raw_ids.size + 1) do |job|
      ids = [] of Steam::ID
      raw_ids.each do |string_id|
        begin
          id = Steam::ID.new(string_id)
          # Enforce Public universe bit (STEAM_1..) and Individual account type:
          id.universe = :public
          id.account_type = :individual
          id.instance = 1

          ids << id
        rescue ex : Steam::ID::Error
          job.send Job::Error.new(string_id, ex.message)
        end
      end

      # TODO: check if more than 100, maybe do this in middleware
      # for request validation
      players = @client.get_players(ids)
      player_ids = players.map &.id

      invalid_ids = [] of Steam::ID
      ids.each do |id|
        unless player_ids.includes? id
          invalid_ids << id
          job.send Job::Error.new(
            id.to_s(Steam::ID::Format::Default),
            "Not found"
          )
        end
      end

      lender_ids = [] of Steam::ID

      players.each do |player|
        lender_id = @client.get_lender_id(player.id)
        lender_ids << lender_id unless lender_id.nil?

        job.send Job::PlayerResult.new(player, lender_id)
      end

      unless lender_ids.empty?
        lenders = @client.get_players(lender_ids)
        job.send Job::BatchPlayers.new(lenders)
      else
        job.send Job::BatchPlayers.new
      end
    end

    context.response.content_type = "application/json"
    context.response.puts({nonce: nonce}.to_json)
  end

  def call(context : HTTP::Server::Context)
    case context.request.path
    when "/"          then context.response.print(Kilt.render("views/index.slang"))
    when "/api/check" then handle_check(context)
    else
      call_next(context)
    end
  end
end
