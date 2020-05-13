require "./gmod_checker"

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
