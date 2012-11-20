require 'bundler/setup'
require 'celluloid/zmq'
require 'celluloid/io'
require 'json'
require 'rethinkdb'
require 'socket'
require 'websocket'

BASE_DIR = File.expand_path(File.dirname(__FILE__)+"/../../")
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))

Celluloid::ZMQ.init

module Wopr
  class Woprd
    include Celluloid::ZMQ
    extend RethinkDB::Shortcuts

    def initialize
      zmq_setup
      @rdb_config = SETTINGS["wopr"]["rethinkdb"]
      db_setup
    end

    def zmq_setup
      @addr = SETTINGS["wopr"]["woprd"]["addr"]
      @zpub = PubSocket.new
      puts "woprd pub on #{@addr}"
      @zpub.bind(@addr)

      @addr = SETTINGS["wopr"]["exchange"]["addr"]
      @zsub = SubSocket.new
      puts "woprd sub on #{@addr}"
      @zsub.subscribe('E')
      @zsub.connect(@addr)
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
      puts "#{@addr}: #{msg}"
    end
  end

  class WoprSocket
    include Celluloid::IO

    def websocket_mainloop
      puts "Socket 2000 listening"
      server = TCPServer.new 'localhost', 2000
      loop do
        handle_connection! server.accept
      end
    end

    def handle_connection(client)
      puts "Socket 2000 client accepted"
      handshake = WebSocket::Handshake::Server.new
      begin
        client.write "Hello. Time is #{Time.now}\n"
        until handshake.finished?
          puts "not finished"
          msg = client.readpartial(4096)
          puts "read: #{msg}"
          handshake << msg
        end
        puts "handshake valid: #{handshake.valid?}"
      rescue EOFError
        puts "client EOF"
      end
    end
  end
end

wopr = Wopr::Woprd.new
wopr.zmq_mainloop!
wsock = Wopr::WoprSocket.new
wsock.websocket_mainloop
puts "end-of-the-world"