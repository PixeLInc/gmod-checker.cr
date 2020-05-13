require "./spec_helper"

def it_serializes(object, to string)
  pending "serializes #{object} into #{string}" do
    result = serialize(0, object)
    result.should eq string
  end
end

describe "#serialize" do
  player = Steam::Player.new(
    id: Steam::ID.new(1),
    persona_name: "persona_name",
    avatar: "avatar",
    profile_url: "profile_url")
  player_json = player.to_json

  it_serializes(
    Job::PlayerResult.new(player: player, lender_id: Steam::ID.new(0_i64)),
    to: %({"nonce":"0","type":"player_result","data":{"player":#{player_json},"lender_id":"0"}})
  )

  it_serializes(
    Job::PlayerResult.new(player: player, lender_id: nil),
    to: %({"nonce":"0","type":"player_result","data":{"player":#{player_json},"lender_id":null}})
  )

  it_serializes(
    Job::Error.new(id: "invalid id", message: "message"),
    to: %({"nonce":"0","type":"error","message":"message","data":"invalid id"})
  )
end
