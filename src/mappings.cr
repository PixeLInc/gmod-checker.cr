require "json"

module Steam
  module Responses
    record(
      SteamInfo,
      sharing : Bool = false,
      lender_user : SteamUser? = nil,
      steam_user : SteamUser? = nil)

    struct SteamUser
      JSON.mapping(
        id: {type: String?, default: nil},
        community_id: {type: String, key: "steamid"},
        persona_name: {type: String, key: "personaname"},
        avatar: {type: String, key: "avatarfull"}
      )
    end

    struct Shared
      JSON.mapping(
        lender: {type: String, key: "lender_steamid"}
      )
    end

    struct SteamGame
      JSON.mapping(
        app_id: {type: Int32, key: "appId"},
        name: String,
        playtime_two_weeks: {type: Float32, key: "playtime_2weeks"},
        playtime_forever: Float32,
        img_logo_url: String
      )
    end
  end

  module SteamResponseConverter
    def self.from_json(string : String)
      from_json JSON::PullParser.new(string)
    end

    def self.from_json(parser : JSON::PullParser)
      results = [] of Responses::SteamUser
      parser.on_key("response") do
        parser.on_key("players") do
          results = Array(Responses::SteamUser).new(parser)
        end
      end
      results
    end
  end
end
