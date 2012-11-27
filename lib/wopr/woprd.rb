require 'celluloid/zmq'
require 'celluloid/io'
require 'rethinkdb'
require 'socket'
require 'websocket'

module Wopr
  class Woprd
    include Celluloid::ZMQ
    extend RethinkDB::Shortcuts

    def initialize
      @rdb_config = SETTINGS["wopr"]["rethinkdb"]
      db_setup
      zmq_setup
      websocket_setup
    end

    def websocket_setup
      @wsock = Wopr::WoprSocket.new
      @wsock.websocket_mainloop!
    end

    def zmq_setup
      @addr = SETTINGS["wopr"]["woprd"]["addr"]
      @zpub = PubSocket.new
      puts "woprd pub on #{@addr}"
      @zpub.bind(@addr)

      @zsub = SubSocket.new
      @zsub.subscribe('E')
      db.table('exchanges').run.each do |exchange|
        puts "woprd sub #{exchange["name"]} on #{exchange["zmq_pub"]}"
        @zsub.connect(exchange["zmq_pub"])
      end
    end

    def db
      self.class.r.db(@rdb_config["db"])
    end

    def db_setup
      begin
        puts "Connecting to #{@rdb_config["host"]}:#{@rdb_config["db"]}"
        self.class.r.connect(@rdb_config["host"], @rdb_config["port"])
        unless self.class.r.db_list.run.include?(@rdb_config["db"])
          self.class.r.db_create(@rdb_config["db"]).run
          puts "Warning: created database #{@rdb_config["db"]}"
        end

        unless db.table_list.run.include?('exchanges')
          db.table_create('exchanges').run
          puts "Warning: created table 'exchanges'"
        end

        ecount = db.table('exchanges').count.run
        puts "#{ecount} exchanges found"
      rescue Errno::ENETUNREACH => e
        puts "! Failed connecting to #{@rdb_config["host"]}:#{@rdb_config["db"]}"
      end
    end

    def zmq_mainloop
      puts "zmq listening"
      loop { handle_message!(@zsub.read) }
    end

    def handle_message(msg)
      puts "<- #{@addr}: #{msg}"
      @wsock.send_all!(msg)
    end
  end

  class WoprSocket
    include Celluloid::IO

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
      puts "Socket 2000 client #{client_id} #{@clients.size}"
      handshake = WebSocket::Handshake::Server.new
      begin
        until handshake.finished?
          msg = client.readpartial(4096)
          handshake << msg
        end
        puts "handshake valid: #{handshake.valid?}"
        if handshake.valid?
          @clients.update(client_id => {socket: client,
                                        ws_version: handshake.version})
          puts "Responding to handshake"
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
          puts "#{client_id} MSG #{msg.type}#{msg.type == :text ? ": #{msg}" : "."}"
        end
      end
    end

    def send_all(json)
      @clients.each do |client_id, client|
        puts "Sending to #{client_id}"
        out_frame = WebSocket::Frame::Outgoing::Server.new(:version => client[:ws_version],
                                                           :data => json,
                                                           :type => :text)
        client[:socket].write out_frame.to_s
      end
    end
  end
end
