module Wopr
  class Web
    include Celluloid::IO

    def initialize(woprd)
      @woprd = woprd
    end

    def websocket_mainloop
      @clients = {}
      puts "Socket 2000 listening"
      server = TCPServer.new 'localhost', 2000
      loop do
        handle_connection! server.accept
      end
    end

    def handle_connection(client)
      client_addr = client.peeraddr(:numeric)
      client_id = "#{client_addr[3]}:#{client_addr[1]}"
      puts "ws client #{client_id}"
      handshake = WebSocket::Handshake::Server.new
      begin
        until handshake.finished?
          msg = client.readpartial(4096)
          handshake << msg
        end
        puts "handshake valid: #{handshake.valid?}"
        if handshake.valid?
          @clients.update(client_id => {socket: client,
                                        ws_version: handshake.version,
                                        id: client_id})
          client.write handshake.to_s
          loop { read_frame(client_id) }
        end

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
      puts "-> #{client[:id]} #{json_msg}"
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