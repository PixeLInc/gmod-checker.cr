module Steam
  class Converter

    def self.to_community(steam_id : String?) : Int64
      if steam_id =~ /^STEAM_[0-1]:([0-1]:[0-9]+)$/
        split = $1.split(':')

        ((split[1].to_i * 2).to_i64 + split[0].to_i) + 76561197960265728
      elsif steam_id =~ /^\[U:([0-1]:[0-9]+)\]$/
        0_i64
      else
        0_i64
      end
    end

    def self.from_community(community_id : Int64)
      y = community_id - 76561197960265728
      x = y % 2

      "STEAM_0:#{x}:#{(y - x) / 2}"
    end

  end

  class API
    @@steam_api_key = "hey wow, an api key goes here!"

    enum Type
      Sharing
      Recent
    end

    def self.get_names(steam_ids : Array(Int64))
      results = {} of String => Responses::Summaries::SteamUser

      url = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=#{@@steam_api_key}&steamids=%s" % steam_ids.join(",")

      p url

      resp = HTTP::Client.get url
      parser = JSON::PullParser.new(resp.body.lines.join('\n'))

      parser.on_key("response") do
        summaries = Responses::Summaries.new(parser)

        return nil if summaries.players.size <= 0

        summaries.players.each do |player|
          s_id = Converter.from_community(player.c_id.to_i64)
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
      {community_id, self.parse_response(response.body.lines, type)}
    end

    def self.parse_response(response : Array(String), type : Type)
      parser = JSON::PullParser.new(response.join('\n'))
      results = Responses::SteamInfo.new()

      case type
      when Type::Sharing
        parser.on_key("response") do
          shared = Steam::Responses::Shared.new(parser)

          if shared.lender != "0"
            results.sharing = true
            results.lender = shared.lender
          end
        end
      end

      results
    end
  end
end
