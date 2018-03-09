require "raze"
require "kilt/slang"
require "http/client"
require "json"
require "./steam.cr"
require "./mappings.cr"

module Steam

  get "/" do |ctx|
    render("views/index.slang")
  end

  def self.run_check(steam_ids)
    results = API.send_request(steam_ids)

    p results

    results
  end

  get "/check" do |ctx|
    sids = ctx.query["steamids"]?

    ctx.halt({"error": "Invalid Steam ID(s) passed"}.to_json, 400) if !sids || sids == ""
    ctx.response.content_type = "application/json"

    if sids.is_a?(String)
      sids = sids.gsub(/\s+/, "").split(',')
      sids, _bad = sids.partition { |id| id.match(/^STEAM_[0-5]:[01]:\d+$/) }
      results = self.run_check(sids)

      {"type" => "batch_result", "results" => [results]}.to_json
    end
  end

  ws "/ws" do |ws, ctx|
    puts "We got a new socket connection!"

    ws.on_message do |msg|
      puts "New Message! #{msg}"
      # Just send some random data back for now.

      ws.send({"type" => "result", "title" => "REEEEEE", "desc" => "r e e e e e"}.to_json)
    end
  end

end


Raze.run
