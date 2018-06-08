require "http/client"
require "./id"
require "./mappings"

class Steam::Client
  BASE_URL = "http://api.steampowered.com"

  def initialize(@api_key : String)
  end

  def request(endpoint : String)
    response = HTTP::Client.get "#{BASE_URL}#{endpoint}&key=#{@api_key}"
    raise "Request failed: #{response.inspect}" unless response.success?
    # TODO: Implement some sort of ratelimiter here or something.
    response.body
  end

  def parse(type, from io, in key)
    parser = JSON::PullParser.new(io)
    object = nil
    parser.on_key("response") do
      parser.on_key(key) do
        object = type.new(parser)
      end
    end
    object.not_nil!
  end

  def get_players(player_ids : Array(ID)) : Array(Player)
    query = HTTP::Params.build do |form|
      form.add "steamids", player_ids.map { |id| id.to_steam_64 }.join(',')
    end
    response = request("/ISteamUser/GetPlayerSummaries/v0002?#{query}")
    parse(Array(Player), from: response, in: "players")
  end

  def get_lender_id(player_id : ID)
    query = HTTP::Params.build do |form|
      form.add "steamid", player_id.to_steam_64.to_s
      form.add "appid_playing", "4000"
      form.add "format", "json"
    end
    response = request("/IPlayerService/IsPlayingSharedGame/v0001?#{query}")
    value = parse(String, from: response, in: "lender_steamid")
    ID.new(value.to_i64) unless value == "0"
  end
end
