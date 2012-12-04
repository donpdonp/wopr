require 'reel'

module Wopr
  class Web

    def initialize(woprd)
      @woprd = woprd
    end

    def websocket_mainloop
      @clients = {}
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
            handle_connection(request)
            connection.close
            break
          end
        end
      end
    end

    def handle_connection(request)
      #equest.socket.peeraddr(:numeric)
      client_id =  "#{request.remote_ip}"
      puts request.inspect
      @clients.update(:client_id => {request: request})
      begin
        loop { read_frame(request) }
      rescue EOFError
        @clients.delete(client_id)
        puts "client EOF"
      end
    end

    def read_frame(client_id)
      client = @clients[client_id]
      frame = WebSocket::Frame::Incoming::Server.new(:version => client[:ws_version])
      loop do
        data = client[:socket].readpartial(4096)
        frame << data
        msg = frame.next
        if msg
          dispatch(client, msg)
        end
      end
    end

    def dispatch(client, msg)
      puts "#{client[:id]} MSG #{msg.type}#{msg.type == :text ? ": #{msg}" : "."}"
      case msg.type
      when :ping
        puts "ws ping"
        out_frame = WebSocket::Frame::Outgoing::Server.new(:version => client[:ws_version],
                                                           :data => "",
                                                           :type => :pong)
        client[:socket].write out_frame.to_s

      when :text
        if msg.to_s == "RELOAD"
          baseframe(client)
        end
      end
    end

    def send_all(type, json)
      @clients.each do |client_id, client|
        push(client, type, json)
      end
    end

    def push(client, type, obj)
      json_rpc = {"response" => obj,
                  "type" => type,
                  "id" => 0}
      json_msg = json_rpc.to_json
      puts "-> #{client[:id]} #{type}"
      out_frame = WebSocket::Frame::Outgoing::Server.new(:version => client[:ws_version],
                                                         :data => json_msg,
                                                         :type => :text)
      client[:socket].write out_frame.to_s
    end

    def baseframe(client)
      push(client, 'load', @woprd.profitable_bids)
    end
  end
end