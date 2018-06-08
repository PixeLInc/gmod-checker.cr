require "json"

module Steam
  struct Player
    JSON.mapping(
      id: {type: ID, key: "steamid"},
      persona_name: {type: String, key: "personaname"},
      avatar: {type: String, key: "avatarfull"},
      profile_url: {type: String, key: "profileurl"}
    )
  end

  struct Game
    JSON.mapping(
      app_id: {type: Int32, key: "appId"},
      name: String,
      playtime_two_weeks: {type: Float32, key: "playtime_2weeks"},
      playtime_forever: Float32,
      img_logo_url: String
    )
  end

  # module SteamResponseConverter
  #   def self.from_json(string : String)
  #     from_json JSON::PullParser.new(string)
  #   end
  #
  #   def self.from_json(parser : JSON::PullParser)
  #     results = [] of Responses::SteamUser
  #     parser.on_key("response") do
  #       parser.on_key("players") do
  #         results = Array(Responses::SteamUser).new(parser)
  #       end
  #     end
  #     results
  #   end
  # end
end
