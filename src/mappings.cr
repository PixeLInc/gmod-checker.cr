require "json"

module Steam
  struct Player
    include JSON::Serializable

    @[JSON::Field(key: "steamid")]
    getter id : ID

    @[JSON::Field(key: "personaname")]
    getter persona_name : String

    @[JSON::Field(key: "avatarfull")]
    getter avatar : String

    @[JSON::Field(key: "profileurl")]
    getter profile_url : String

    # :nodoc:
    def initialize(@id : ID, @persona_name : String, @avatar : String,
                   @profile_url : String)
    end
  end

  struct Game
    include JSON::Serializable

    @[JSON::Field(key: "appId")]
    getter app_id : Int32

    getter name : String

    @[JSON::Field(key: "playtime_2weeks")]
    getter playtime_two_weeks : Float32

    @[JSON::Field(key: "playtime_forever")]
    getter playtime_forever : Float32

    @[JSON::Field(key: "img_logo_url")]
    getter image_logo_url : String
  end
end
