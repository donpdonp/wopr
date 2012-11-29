require 'bundler/setup'
require 'faraday'
require 'wopr/exchange_actor'
require 'json'
require 'celluloid/io'
require 'websocket'
require 'rethinkdb'

module Wopr
  module Exchanges
    module Btce
      class Rest
        include Celluloid::ZMQ
        include Wopr::ExchangeActor
        extend RethinkDB::Shortcuts

        def initialize
          db_setup(self.class.r)
          zmq_setup(PubSocket.new, SubSocket.new, "Btce")
        end

        def depth_poll(conn, from_currency, to_currency)
          # covers two markets, from/to and to/from
          url = 'https://btc-e.com/api/2/btc_usd/depth'
          JSON.parse(conn.get(url).body)
        end

        def offers(data, bidask, now)
          msgs = data[bidask].map do |offer|
            { exchange: 'btce',
              bidask: bidask[0,3],
              listed_at: now,
              price: offer.first,
              quantity: offer.last,
              currency: 'usd'
            }
          end
          msgs.each {|msg| @zpub.write('E'+msg.to_json)}
        end

        def offer_pump
          net = Faraday.new(request:{timeout:10})
          puts "btce http"
          now = Time.now
          data = depth_poll(net, 'btc', 'usd')
          puts "btce pump #{data["asks"].size} asks"
          offers(data, 'asks', now)
          puts "btce pump #{data["asks"].size} bids"
          offers(data, 'bids', now)
        end
      end
    end
  end
end

e1 = Wopr::Exchanges::Btce::Rest.new
loop do
  e1.offer_pump
  sleep 5
end
