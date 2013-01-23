module Wopr
  class Web
    include Celluloid::IO

    def initialize(woprd)
      @woprd = woprd
    end

    def websocket_mainloop
      @clients = {}
      port = 2000
      puts "websockets on http://localhost:#{port}"
      server = TCPServer.new 'localhost', port
      loop do
        handle_connection! server.accept
      end
    end

    def handle_connection(client)
      client_addr = client.peeraddr(:numeric)
      client_id = "#{client_addr[3]}:#{client_addr[1]}"
      puts "websocket connection #{client_id}"
      handshake = WebSocket::Handshake::Server.new
      begin
        until handshake.finished?
          msg = client.readpartial(4096)
          handshake << msg
        end
        if handshake.valid?
          @clients.update(client_id => {socket: client,
                                        ws_version: handshake.version,
                                        id: client_id})
          client.write handshake.to_s
          loop { read_frame(client_id) }
        else
          puts "websocket handshake invalid from #{client_id}"
        end

      rescue EOFError
        @clients.delete(client_id)
        puts "client EOF #{client_id}"
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
      puts "<-ws #{client[:id]} #{msg.type == :text ? msg : msg.type}"
      case msg.type
      when :ping
        puts "<-ws ping"
        out_frame = WebSocket::Frame::Outgoing::Server.new(:version => client[:ws_version],
                                                           :data => "",
                                                           :type => :pong)
        puts "ws-> pong"
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
      puts "ws-> #{client[:id]} #{type}"
      out_frame = WebSocket::Frame::Outgoing::Server.new(:version => client[:ws_version],
                                                         :data => json_msg,
                                                         :type => :text)
      client[:socket].write out_frame.to_s
    end

    def baseframe(client)
      offers = @woprd.profitable_bids
      push(client, 'load', offers)
    end
  end
end