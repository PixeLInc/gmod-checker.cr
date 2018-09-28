require "./spec_helper"

record IDStub, id_64 : UInt64, id_32 : String, id_3 : String

describe Steam::ID do
  id_stubs = {
    IDStub.new(
      76561198072216199,
      "STEAM_0:1:55975235",
      "[U:1:111950471]"),
    IDStub.new(
      76561197960361544,
      "STEAM_0:0:47908",
      "[U:1:95816]"),
    IDStub.new(
      76561198085325954,
      "STEAM_0:0:62530113",
      "[U:1:125060226]"),
  }

  it "parses ID 32 format" do
    id_stubs.each do |data|
      id = Steam::ID.new(data.id_32)

      # Universe is wrong:
      id.universe = :public

      # ID 32 does not include instance or account type:
      id.instance = 1
      id.account_type = :individual

      id.to_u64.should eq data.id_64
    end
  end

  it "parses ID 3 format" do
    id_stubs.each do |data|
      id = Steam::ID.new(data.id_3)

      # ID 3 does not include universe or instance:
      id.universe = :public
      id.instance = 1

      id.to_u64.should eq data.id_64
    end
  end

  it "serializes ID 32 format" do
    id_stubs.each do |data|
      id = Steam::ID.new(data.id_64)

      # Universe is wrong:
      id.universe = :individual

      id.to_s(Steam::ID::Format::Default).should eq data.id_32
    end
  end

  it "serializes ID 3 format" do
    id_stubs.each do |data|
      id = Steam::ID.new(data.id_64)
      id.to_s(Steam::ID::Format::Community32).should eq data.id_3
    end
  end

  describe "#initialize" do
    it "raises with an unknown ID format" do
      expect_raises(Steam::ID::Error) do
        Steam::ID.new("foo")
      end
    end
  end

  it ".new(pull_parser)" do
    parser = JSON::PullParser.new(%("0"))
    expected = Steam::ID.new(0)
    Steam::ID.new(parser).should eq expected
  end
end
