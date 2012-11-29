require 'celluloid/zmq'
require 'celluloid/io'
require 'rethinkdb'
require 'socket'
require 'websocket'
require 'wopr/web'
require 'wopr/market'

module Wopr
  class Woprd
    include Celluloid::ZMQ
    extend RethinkDB::Shortcuts

    def initialize
      @bids = Market.new("bid")
      @asks = Market.new("ask")

      @rdb_config = SETTINGS["wopr"]["rethinkdb"]
      db_setup
      zmq_setup
      websocket_setup
    end

    def websocket_setup
      @wsock = Wopr::Web.new
      @wsock.websocket_mainloop!
    end

    def zmq_setup
      @addr = SETTINGS["wopr"]["woprd"]["addr"]
      @zpub = PubSocket.new
      puts "woprd pub on #{@addr}"
      @zpub.bind(@addr)

      @zsub = SubSocket.new
      @zsub.subscribe('E') #exchange messages
      @zsub.subscribe('P') #performance messages
      db.table('exchanges').run.each do |exchange|
        puts "woprd sub #{exchange["name"]} on #{exchange["zmq_pub"]}"
        @zsub.connect(exchange["zmq_pub"])
      end
    end

    def db
      self.class.r.db(@rdb_config["db"])
    end

    def db_setup
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
    end

    def zmq_mainloop
      puts "zmq listening"
      loop { handle_message!(@zsub.read) }
    end

    def handle_message(json)
      code = json.slice!(0)
      puts "<- #{@addr}: #{code} #{json}"

      msg = JSON.parse(json.force_encoding('UTF-8'))
      case code
      when "E"
        depth(msg)
        #@wsock.send_all!(msg["depth"].to_json)
      when "P"
        @wsock.send_all!(msg.to_json)
      end
    end

    def depth(msg)
      if msg["bidask"] == 'ask'
        market = @asks
      elsif msg["bidask"] == 'bid'
        market = @bids
      end
      rank = market.sorted_insert(msg)
      puts "depth rank #{rank}"
      if rank == 0
        @wsock.send_all!(msg.to_json)
      end
    end
  end

end
