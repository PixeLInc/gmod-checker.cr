require "http/server"
require "log"
require "./steam"
require "./mappings"
require "./job_controller"
require "./handlers/web_router"
require "./handlers/socket_handler"

server = HTTP::Server.new([
  HTTP::ErrorHandler.new,
  HTTP::LogHandler.new,
  HTTP::StaticFileHandler.new("static",
    directory_listing: false),
  Handlers::WebRouter.new,
  Handlers::SocketHandler.new,
])

backend = Log::IOBackend.new
Log.builder.bind "*", :debug, backend

Log.info { "Starting server..." }
server.bind_tcp "127.0.0.1", 8080
server.listen
