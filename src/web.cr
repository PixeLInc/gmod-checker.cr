require "raze"
require "kilt/slang"
require "http/client"
require "logger"
require "./steam"
require "./mappings"
require "./job_controller"

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

logger = Logger.new(STDOUT)
client = Steam::Client.new(ENV["STEAM_API_KEY"], logger)
JobController.logger = logger

get "/" do |ctx|
  render("views/index.slang")
end

post "/api/check" do |ctx|
  # TODO: validate request
  raw_ids = ctx.query["steamids"].split(',')

  # ctx.halt({"error": ""}, 400) if !raw_ids || raw_ids == ""

  nonce = JobController.create(raw_ids.size + 1) do |job|
    ids = [] of Steam::ID
    raw_ids.each do |string_id|
      begin
        id = Steam::ID.new(string_id)
        # Enforce Public universe bit (STEAM_1..) and Individual account type:
        id.universe = :public
        id.account_type = :individual
        ids << id
      rescue ex : Steam::ID::Error
        job.send Job::Error.new(string_id, ex.message)
      end
    end

    # TODO: check if more than 100, maybe do this in middleware
    # for request validation
    players = client.get_players(ids)
    player_ids = players.map &.id

    ids.each do |id|
      unless player_ids.includes? id
        job.send Job::Error.new(
          id.to_s(Steam::ID::Format::Default),
          "Steam ID not found: #{id.to_s(Steam::ID::Format::Default)}"
        )
      end
    end

    lender_ids = [] of Steam::ID

    players.each do |player|
      lender_id = client.get_lender_id(player.id)
      lender_ids << lender_id unless lender_id.nil?

      job.send Job::PlayerResult.new(player, lender_id)
    end

    unless lender_ids.empty?
      lenders = client.get_players(lender_ids)
      job.send Job::BatchPlayers.new(lenders)
    else
      job.send Job::BatchPlayers.new
    end
  end

  {nonce: nonce}.to_json
end

# WS Payloads (spec for each of these):
# {"nonce": 123, "type": "error", "message": "bad id"}
# {"nonce": 123, "type": "result", "data": {"player": {}, "lender_id": "123"}}
# {"nonce": 123, "type": "result", "data": {"player": {}, "lender_id": null}}
ws "/api/relay" do |ws, ctx|
  ws.on_message do |message|
    # Client sends: {"nonce": 123}
    nonce = JobController::Nonce.from_json(message, "nonce")
    JobController.dispatch(nonce) do |result|
      payload = serialize(nonce, result)
      ws.send(payload)
    end
  rescue ex : JSON::ParseException | KeyError
    payload = serialize(nonce, ex)
    ws.send(payload)
  end
end
