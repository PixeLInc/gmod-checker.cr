require "./spec_helper"

describe Steam::Client do
  describe "#parse" do
    client = Steam::Client.new("foo")

    it "parses a single object" do
      json = %({"response": {"foo": "bar"}})
      client.parse(String, from: json, in: "foo").should eq "bar"
    end

    it "parses an array of objects" do
      json = %({"response": {"foo": [1, 2, 3]}})
      client.parse(Array(Int32), from: json, in: "foo").should eq [1, 2, 3]
    end
  end
end
