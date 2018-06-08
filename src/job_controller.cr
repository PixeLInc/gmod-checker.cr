module JobController
  extend self

  alias Nonce = String

  # TODO
  TIMEOUT = 0

  @@jobs = {} of Nonce => Job

  def create(size : Int32, &block : Job ->) : Nonce
    nonce = generate_nonce
    job = Job.new(size)
    @@jobs[nonce] = job
    spawn do
      block.call(job)
    end
    nonce
  end

  def generate_nonce : Nonce
    Random.rand(UInt64::MAX).to_s
  end

  def cleanup(nonce)
    sleep TIMEOUT
    @@jobs.delete(nonce)
  end

  # TODO: Blocking access to jobs with mutex?
  # def get_job(nonce)
  # end

  def dispatch(nonce : Nonce, &block : Job::Result | Job::Error ->)
    job = @@jobs[nonce]
    job.each_result { |r| block.call(r) }
    # TODO: Move into create in its own fiber
    cleanup(nonce)
  end
end

class Job
  struct Result
    JSON.mapping(
      player: Steam::Player,
      lender_id: {type: Steam::ID?, emit_null: true}
    )

    def initialize(@player : Steam::Player, @lender_id : Steam::ID?)
    end
  end

  class Error < Exception
  end

  getter size

  def initialize(@size : Int32)
    @channel = Channel(Result | Error).new(size)
  end

  delegate send, to: @channel

  def each_result
    @size.times do
      yield @channel.receive
    end
  end
end
