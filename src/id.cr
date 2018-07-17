# Type representing Steam IDs. Can be used to convert an ID from one
# Steam ID format to another.
struct Steam::ID
  class Error < Exception
  end

  # Pattern for 32 bit Steam IDs
  STEAM_ID_32_REGEXP = /^STEAM_([0-1]:[0-1]:[0-9]+)$/

  # Pattern for Steam ID 3
  STEAM_ID_3_REGEXP = /^\[U:([0-1]:[0-9]+)\]$/

  @value : Int64

  def self.new(parser : JSON::PullParser)
    value = parser.read_string.to_i64
    new(value)
  end

  def initialize(id : String)
    if id =~ STEAM_ID_32_REGEXP
      universe, low, high = $1.split(':').map &.to_i64
      universe = 1_i64
      @value = (universe << 56) | (1_i64 << 52) | (1_i64 << 32) | (high << 1) | low
    elsif id =~ STEAM_ID_3_REGEXP
      universe, high = $1.split(':').map &.to_i64
      universe = 1_i64
      @value = (universe << 56) | (1_i64 << 52) | (1_i64 << 32) | high
    else
      raise Error.new("Unsupported ID format: #{id}")
    end
  end

  def initialize(@value : Int64)
  end

  def to_json(builder : JSON::Builder)
    builder.string @value.to_s
  end

  # The ID in 64 bit format
  def to_steam_64
    @value
  end

  # The ID in ID 32 format
  def to_steam_32
    # universe = (@value >> 56) & ((1_i64 << 8) - 1_i64)
    id = @value & ((1_i64 << 32) - 1_i64)
    low = id & 1
    high = (id >> 1) & ((1_i64 << 31) - 1_i64)
    "STEAM_0:#{low}:#{high}"
  end

  # The ID in ID 3 format
  def to_steam_3
    universe = (@value >> 56) & ((1_i64 << 8) - 1_i64)
    id = @value & ((1_i64 << 32) - 1_i64)
    "[U:#{universe}:#{id}]"
  end
end
