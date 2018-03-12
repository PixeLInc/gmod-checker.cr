require "./spec_helper"

module Steam::Responses
  describe SteamResponseConverter do
    describe ".from_json" do
      it "parses correctly" do
        players_json = %({"id": "id", "steamid": "steamid", "personaname": "personaname", "avatarfull": "avatarfull"})
        response_json = %({"response": { "players": [#{players_json}]}})
        expected_player = SteamUser.from_json(players_json)

        SteamResponseConverter.from_json(response_json).first.should eq expected_player
      end
    end
  end
end
