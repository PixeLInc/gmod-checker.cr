require "./spec_helper"

def it_serializes(object, to string)
  it "serializes #{object} into #{string}" do
    result = serialize(0, object)
    result.should eq string
  end
end

describe "#serialize" do
  player_json = %({"steamid":"1","personaname":"foo","avatarfull":"bar","profileurl":"url"})
  player = Steam::Player.from_json(player_json)

  it_serializes(
    Job::Result.new(player: player, lender_id: Steam::ID.new(0_i64)),
    to: %({"nonce":"0","type":"result","data":{"player":#{player_json},"lender_id":"0"}})
  )

  it_serializes(
    Job::Result.new(player: player, lender_id: nil),
    to: %({"nonce":"0","type":"result","data":{"player":#{player_json},"lender_id":null}})
  )

  it_serializes(
    Job::Error.new("bad id"),
    to: %({"nonce":"0","type":"error","message":"bad id"})
  )
end
