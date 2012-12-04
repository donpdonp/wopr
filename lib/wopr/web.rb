require 'reel'

module Wopr
  class Web
    include Celluloid::IO

    def self.server(woprd)
      puts "Socket 3000 listening"
      Reel::Server.supervise("0.0.0.0", 3000) do |connection|
        while request = connection.request
          case request
          when Reel::Request
            puts "Client requested: #{request.method} #{request.url}"
            path = request.path + (request.path[-1] == "/" ? "index.html" : "")
            connection.respond :ok, File.read(File.join("html/",path))
          when Reel::WebSocket
            puts "Client made a WebSocket request to: #{request.url}"
            client = Web.new(woprd)
            client.handle_connection(request)
            connection.close
            break
          end
        end
      end
    end

    def initialize(woprd)
      @woprd = woprd
    end

    def handle_connection(request)
      puts request.inspect
      begin
        loop { puts request.read.inspect }
      rescue EOFError
        @clients.delete(client_id)
        puts "client EOF"
      end
    end

    def dispatch(request, msg)
      puts "MSG #{msg}"
      msg = JSON.parse(msg)
      case msg["type"]
      when :text
        if msg.to_s == "RELOAD"
          baseframe(request)
        end
      end
    end

    def send_all(type, json)
      @clients.each do |client_id, client|
        push(client, type, json)
      end
    end

    def push(request, type, obj)
      json_rpc = {"response" => obj,
                  "type" => type,
                  "id" => 0}
      json_msg = json_rpc.to_json
      puts "-> #{client[:id]} #{type}"
      request.write json_msg
    end

    def baseframe(request)
      push(request, 'load', @woprd.profitable_bids)
    end
  end
end