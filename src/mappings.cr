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

    def to_json(builder : JSON::Builder)
      builder.object do
        builder.string "steamid"
        id.to_json(builder)
        builder.field "id_32", id.to_steam_32
        builder.field "personaname", persona_name
        builder.field "avatarfull", avatar
        builder.field "profileurl", profile_url
      end
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
