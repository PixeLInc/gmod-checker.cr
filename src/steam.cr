module Steam
  # Type representing Steam IDs. Can be used to convert an ID from one
  # Steam ID format to another.
  struct ID
    # Pattern for 32 bit Steam IDs
    STEAM_ID_32_REGEXP = /^STEAM_([0-1]:[0-1]:[0-9]+)$/

    # Pattern for Steam ID 3
    STEAM_ID_3_REGEXP = /^\[U:([0-1]:[0-9]+)\]$/

    @value : Int64

    def initialize(id : String)
      if id =~ STEAM_ID_32_REGEXP
        universe, low, high = $1.split(':').map &.to_i64
        @value = (universe << 56) | (1_i64 << 52) | (1_i64 << 32) | (high << 1) | low
      elsif id =~ STEAM_ID_3_REGEXP
        universe, high = $1.split(':').map &.to_i64
        @value = (universe << 56) | (1_i64 << 52) | (1_i64 << 32) | high
      else
        raise "Unsupported ID format: #{id}"
      end
    end

    def initialize(@value : Int64)
    end

    # The ID in 64 bit format
    def to_steam_64
      @value
    end

    # The ID in ID 32 format
    def to_steam_32
      universe = (@value >> 56) & ((1_i64 << 8) - 1_i64)
      id = @value & ((1_i64 << 32) - 1_i64)
      low = id & 1
      high = (id >> 1) & ((1_i64 << 31) - 1_i64)
      "STEAM_#{universe}:#{low}:#{high}"
    end

    # The ID in ID 3 format
    def to_steam_3
      universe = (@value >> 56) & ((1_i64 << 8) - 1_i64)
      id = @value & ((1_i64 << 32) - 1_i64)
      "[U:#{universe}:#{id}]"
    end
  end

  class API
    @@steam_api_key = "hey wow, an api key goes here!"

    enum Type
      Sharing
      Recent
    end

    def self.get_names(steam_ids : Array(Int64))
      results = {} of String => Responses::SteamUser

      url = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=#{@@steam_api_key}&steamids=%s" % steam_ids.join(",")

      p url

      resp = HTTP::Client.get url
      parser = JSON::PullParser.new(resp.body)

      parser.on_key("response") do
        summaries = Array(Responses::SteamUser).from_json(resp.body, "players")

        return nil if summaries.size <= 0

        summaries.each do |player|
          s_id = Steam::ID.new(player.c_id.to_i64)
          player.id = s_id

          results[player.c_id] = player
        end
      end

      results
    end

    def self.send_request(steam_ids : Array(String), type : Type = Type::Sharing)
      # convert all of them to 64's and query server for their names.
      steam_ids = steam_ids.map { |id| Steam::Converter.to_community(id).to_i64 }

      names = self.get_names(steam_ids)

      return {"error": "No players!"} if names.nil?

      results = {} of Int64 => Responses::SteamInfo
      steam_ids.map do |id|
        com, res = self.send_request(id)

        if res.is_a?(String)
          p res
          next
        end

        p res
        res.steam_user = names[com.to_s]

        results[id] = res
      end

      results
    end

    # Meant for one ID at a time!
    def self.send_request(community_id : Int64, type : Type = Type::Sharing)
      send_url = nil

      case type
      when Type::Sharing
        send_url = "http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=#{@@steam_api_key}&steamid=%s&appid_playing=4000&format=json" % community_id
      when Type::Recent
        # make the request, parse the response
      else
        return {"error", "Invalid type"}
      end

      return {"error", "Invalid data"} if send_url.nil?

      response = HTTP::Client.get send_url
      {community_id, self.parse_response(response.body, type)}
    end

    def self.parse_response(response, type : Type)
      results = Responses::SteamInfo.new

      case type
      when Type::Sharing
        shared = Steam::Responses::Shared.from_json(response)

        if shared.lender != "0"
          results.sharing = true
          results.lender = shared.lender
        end
      end

      results
    end
  end
end
