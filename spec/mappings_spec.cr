require "./spec_helper"

module Steam::Responses
  describe Summaries::SteamUser do
    it "can be converted from JSON with a root key" do
      json = <<-JSON
        {
          "players": [
            {"id": "id", "steamid": "steamid", "personaname": "personaname", "avatarfull": "avatarfull"},
            {"id": "id", "steamid": "steamid", "personaname": "personaname", "avatarfull": "avatarfull"},
            {"id": "id", "steamid": "steamid", "personaname": "personaname", "avatarfull": "avatarfull"}
          ]
        }
        JSON
      Array(Summaries::SteamUser).from_json(json, "players")
    end
  end
end
