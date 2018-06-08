require "./spec_helper"

record IDStub, id_64 : Int64, id_32 : String, id_3 : String

describe Steam::ID do
  id_stubs = {
    IDStub.new(
      76561198072216199_i64,
      "STEAM_1:1:55975235",
      "[U:1:111950471]"),
    IDStub.new(
      76561197960361544_i64,
      "STEAM_1:0:47908",
      "[U:1:95816]"),
  }

  it "parses ID 32 format" do
    id_stubs.each do |data|
      id = Steam::ID.new(data.id_32)
      id.to_steam_64.should eq data.id_64
    end
  end

  it "parses ID 3 format" do
    id_stubs.each do |data|
      id = Steam::ID.new(data.id_3)
      id.to_steam_64.should eq data.id_64
    end
  end

  it "serializes ID 32 format" do
    id_stubs.each do |data|
      id = Steam::ID.new(data.id_64)
      id.to_steam_32.should eq data.id_32
    end
  end

  it "serializes ID 3 format" do
    id_stubs.each do |data|
      id = Steam::ID.new(data.id_64)
      id.to_steam_3.should eq data.id_3
    end
  end

  describe "#initialize" do
    it "raises with an unknown ID format" do
      expect_raises(Steam::ID::Error, "Unsupported ID format: foo") do
        Steam::ID.new("foo")
      end
    end
  end

  it ".new(pull_parser)" do
    parser = JSON::PullParser.new(%("0"))
    expected = Steam::ID.new(0_i64)
    Steam::ID.new(parser).should eq expected
  end
end
