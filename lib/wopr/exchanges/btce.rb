require 'bundler/setup'
require 'faraday'
require 'wopr/exchange_actor'
require 'json'
require 'celluloid/io'
require 'rethinkdb'
require 'uuid'

module Wopr
  module Exchanges
    module Btce
      class Rest
        include Celluloid::ZMQ
        include Wopr::ExchangeActor
        extend RethinkDB::Shortcuts

        def initialize
          @exchange = "btce"
          db_setup(self.class.r)
          zmq_setup(PubSocket.new, SubSocket.new, "Btce")
        end

        def depth_poll(conn, from_currency, to_currency)
          # covers two markets, from/to and to/from
          url = 'https://btc-e.com/api/2/btc_usd/depth'
          json = conn.get(url).body
          begin
            JSON.parse(json)
          rescue JSON::ParserError
            puts "JSON error: #{json}"
          end
        end

        def offers(data, bidask, now)
          msgs = data[bidask].map do |offer|
            { id: UUID.generate,
              exchange: 'btce',
              bidask: bidask[0,3],
              listed_at: now,
              price: offer.first,
              quantity: offer.last,
              currency: 'usd'
            }
          end
          msgs.each do |msg|
            @zpub.write('E'+msg.to_json)
          end
        end

        def offer_pump
          net = Faraday.new(request:{timeout:10})
          puts "btce http"
          now = Time.now
          data = depth_poll(net, 'btc', 'usd')
          puts "wiping #{@exchange}"
          @zpub.write('W'+{exchange:@exchange}.to_json)
          puts "btce pump #{data["asks"].size} asks"
          offers(data, 'asks', now)
          puts "btce pump #{data["bids"].size} bids"
          offers(data, 'bids', now)
        end
      end
    end
  end
end

e1 = Wopr::Exchanges::Btce::Rest.new
e1.offer_pump
e1.run
