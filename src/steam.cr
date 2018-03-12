module Steam
  # Type representing Steam IDs. Can be used to convert an ID from one
  # Steam ID format to another.
  struct ID
    class InvalidIDException < Exception
    end

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
        raise InvalidIDException.new("Unsupported ID format: #{id}")
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

  class Client
    BASE_URL = "http://api.steampowered.com"

    def initialize(@api_key : String)
    end

    def names(steam_infos : Array(Responses::SteamInfo))
      results = {} of String => Responses::SteamUser

      query = HTTP::Params.build do |form|
        form.add "steamids", steam_infos.map { |info| id.to_steam_64 }.join(',')
      end
      repsonse = get("/ISteamUser/GetPlayerSummaries/v0002?#{query}")

      users = SteamResponseConverter.from_json(response)
      users.each do |user|
        id = ID.new(user.community_id)
        user.id = id.to_steam_32
        results[id.to_steam_64] = user
      end

      results
    end

    def sharing_info(steam_ids : Array(Steam::ID))
      # Check the supplied steam ids against steam for sharing.
      steam_ids.map do |steam_id|
        query = HTTP::Params.build do |form|
          form.add "steam_id", steam_id.to_steam_64
          form.add "appid_playing", "4000"
          form.add "format", "json"
        end

        response = get("/IPlayerService/IsPlayingSharedGame/v0001?#{query}")

        parse_response(response, steam_id)
      end

      # return Array(SteamUser) here?
    end

    def get(endpoint : String)
      response = HTTP::Client.get "#{BASE_URL}#{endpoint}&key=#{@api_key}"
      response.body
    end

    def parse_response(response, original_id, type : Type = Type::Sharing)
      sharing = false
      lender = nil

      case type
      when Type::Sharing
        shared = Steam::Responses::Shared.from_json(response)

        sharing = true
        lender = shared.lender
      end

      Responses::SteamInfo.new(sharing, original_id, lender)
    end
  end
end
