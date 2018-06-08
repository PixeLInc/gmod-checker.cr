require "./spec_helper"

player = Steam::Player.from_json %({"steamid": "1", "personaname": "foo", "avatarfull": "bar", "profileurl": "url"})
objects = {
  Job::Result.new(player: player, lender_id: Steam::ID.new(0_i64)),
  Job::Result.new(player: player, lender_id: nil),
  Job::Error.new("foo")
}

describe Job do
  it "sends and receives" do
    job = Job.new(3)

    objects.each { |o| job.send(o) }

    i = 0
    job.each_result do |result|
      result.should eq objects[i]
      i += 1
    end

    i.should eq 3
  end
end

describe JobController do
  describe ".create" do
    it "creates a fiber with a new job" do
      done = Channel(Nil).new
      JobController.create(3) do |job|
        job.size.should eq 3
        done.send(nil)
      end
      done.receive
    end
  end

  describe ".dispatch" do
    it "dipatches all buffered objects" do
      nonce = JobController.create(3) do |job|
        objects.each { |o| job.send(o) }
      end

      i = 0
      JobController.dispatch(nonce) do |result|
        result.should eq objects[i]
        i += 1
      end

      expect_raises(KeyError) do
        JobController.dispatch(nonce) {}
      end
    end

    it "raises on an unknown nonce" do
      expect_raises(KeyError) do
        JobController.dispatch(0_u64) {}
      end
    end
  end
end
