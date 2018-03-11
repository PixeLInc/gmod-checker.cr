require "json"

module Steam
  module Responses
    record(
      SteamInfo,
      sharing : Bool? = false,
      lender_user : SteamUser? = nil,
      steam_user : SteamUser? = nil)

    class SteamUser
      JSON.mapping(
        id: {type: String?, default: nil},
        c_id: {type: String, key: "steamid"},
        personaname: String,
        avatar: {type: String, key: "avatarfull"}
      )
    end

    class Shared
      JSON.mapping(
        lender: {type: String, key: "lender_steamid"}
      )
    end

    class Recent
      class SteamGame
        JSON.mapping(
          appId: Int32,
          name: String,
          playtime_2weeks: Float32,
          playtime_forever: Float32,
          img_logo_url: String
        )
      end
    end
  end
end
