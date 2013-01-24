module Wopr
  class Woprd
    include Celluloid::ZMQ
    extend RethinkDB::Shortcuts

    def initialize
      @bids = Market.new("bid")
      @asks = Market.new("ask")
      @exchanges = {}

      @rdb_config = SETTINGS["wopr"]["rethinkdb"]
      db_setup
      zmq_setup
      websocket_setup
    end

    def websocket_setup
      @wsock = Wopr::Web.new(self)
      @wsock.websocket_mainloop!
    end

    def zmq_setup
      @addr = SETTINGS["wopr"]["woprd"]["addr"]
      @zpub = PubSocket.new
      puts "woprd pub on #{@addr}"
      @zpub.bind(@addr)

      @zsub = SubSocket.new
      @zsub.subscribe('E') #exchange messages
      @zsub.subscribe('W') #exchange wipe
      @zsub.subscribe('P') #performance messages
      @zsub.subscribe('p') #ping messages
      db.table('exchanges').run.each do |exchange|
        @exchanges[exchange["name"]] = exchange
        puts "woprd subcribed to #{exchange["name"]} on #{exchange["zmq_pub"]}"
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
      puts "* zmq ready."
      loop { handle_message!(@zsub.read) }
    end

    def handle_message(json)
      code = json.slice!(0)
      puts "<-zq #{@addr}: #{code} #{json}"

      msg = JSON.parse(json.force_encoding('UTF-8'))
      case code
      when "E" #Exchange
        depth(msg)
        #@wsock.send_all!(msg["depth"].to_json)
      when "W" #Exchange wipe
        wipe(msg["exchange"])
      when "P" #Performance
        @wsock.send_all!('performance', msg)
      when "p" #ping
        puts 'got ping'
        pub('p{"ong":true}')
      end
    end

    def pub(msg)
      puts "-> #{msg}"
      @zpub.write(msg)
    end

    def depth(msg)
      exclusive do
        if msg["bidask"] == 'ask'
          market = @asks
        elsif msg["bidask"] == 'bid'
          market = @bids
        end
        rank = market.sorted_insert(msg)
        puts "sorted insert #{msg["bidask"]}: price #{msg["price"]} rank #{rank}/#{market.offers.size}  "
        if rank == 0
          if msg["volume"] == 0
            puts "** best just got cancelled."
            if market.offers.size == 0
              puts "** last offer cancelled. empty market"
            else
              best = market.offers[0]
              puts "** new second best #{best["bidask"]} #{best["exchange"]} #{best["price"]}"
            end
          else
            puts "** new best #{msg["bidask"]} #{msg["exchange"]} #{msg["price"]}"
          end
        end
      end
    end

    def profitable_bids
      exclusive do
        best_bid = @bids.best
        best_ask = @asks.best
        puts "ask ex #{best_ask["exchange"]} #{@exchanges[best_ask["exchange"]]}"
        best_asks = @asks.better_than(best_bid["price"])
        best_bids = @bids.better_than(best_ask["price"])
        total_asks_usd = best_asks.reduce(0){|total, offer| total + offer["price"]*offer["quantity"]}
        total_asks_btc = best_asks.reduce(0){|total, offer| total + offer["quantity"]}
        puts "best ask price #{best_ask["price"]} #{best_ask["exchange"]} qualifying asks count #{best_asks.size}"
        total_bids = best_bids.reduce(0){|total, offer| total + offer["price"]*offer["quantity"]}
        puts "best bid price #{best_bid["price"]} #{@bids.best["exchange"]} qualifying bids count #{best_bids.size}"
        {asks: best_asks, total_asks_usd:total_asks_usd, total_asks_btc: total_asks_btc,
         bids: best_bids, total_bids_usd:total_bids, total_bids_btc: 0}
       end
    end

    def wipe(exchange)
      exclusive do
        before_asks = @asks.offers.size
        before_bids = @bids.offers.size
        @bids.remove_exchange(exchange)
        @asks.remove_exchange(exchange)
        puts "Wiped #{exchange} change: #{before_asks-@asks.offers.size} asks. #{before_bids-@bids.offers.size} bids."
      end
    end
  end

end
