module Steam
  module Responses

    record SteamInfo, sharing : Bool? = false, lender : String? = nil, lender_name : String? = nil, steam_user : Summaries::SteamUser? = nil do
      JSON.mapping(
        sharing: {type: Bool?, default: false},
        lender: {type: String?, default: nil},
        lender_name: {type: String?, default: nil},
        steam_user: {type: Summaries::SteamUser?, default: nil}
      )
    end

    class Summaries
      class SteamUser
        JSON.mapping(
          id: {type: String?, default: nil},
          c_id: {type: String, key: "steamid"},
          personaname: String,
          avatar: {type: String, key: "avatarfull"}
        )
      end

      JSON.mapping(
        players: Array(SteamUser)
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

      JSON.mapping(
        games: Array(SteamGame)
      )
    end

  end
end
