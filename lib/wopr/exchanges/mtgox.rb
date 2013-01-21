require 'bundler/setup'
require 'httparty'
require 'faraday'
require 'wopr/exchange_actor'
require 'json'
require 'celluloid/io'
require 'websocket'
require 'rethinkdb'

module Wopr
  module Exchanges
    module Mtgox
      class Rest
        include Celluloid::ZMQ
        include Wopr::ExchangeActor
        extend RethinkDB::Shortcuts

        def initialize
          @exchange = "mtgox"
          db_setup(self.class.r)
          zmq_setup(PubSocket.new, SubSocket.new, "Mtgox")
        end

        def depth_poll(conn, from_currency, to_currency)
          # covers two markets, from/to and to/from
          if File.exists?("mtgox.json")
            puts "file cache"
            body = File.open("mtgox.json"){|f| f.read}
          else
            url = "https://mtgox.com/api/1/#{from_currency.upcase}#{to_currency.upcase}/fulldepth"
            body = conn.get(url).body
          end
          JSON.parse(body)
        end

        def offers(data, bidask)
          data[bidask].map do |offer|
            { id: UUID.generate,
              exchange: @exchange,
              bidask: bidask[0,3],
              listed_at: Time.at(offer["stamp"].to_i/1000000),
              price: offer["price"],
              quantity: offer["amount"],
              currency: 'usd'
            }
          end
        end

        def offer_pump
          net = Faraday.new(request:{timeout:10})
          puts "** #{@exchange} begin"
          now = Time.now
          data = depth_poll(net, 'btc', 'usd')
          puts "http transfer delay #{Time.now-now}s"
          if data["result"] == "success"
            now = Time.now
            offers = data["return"]
            puts "return data contains: #{offers.keys.join(' ')}"
            puts "wiping #{@exchange}"
            @zpub.write('W'+{exchange:@exchange}.to_json)
            puts "pumping mtgox #{offers["asks"].size} asks"
            msgs = offers(offers, 'asks')
            msgs.each {|msg| @zpub.write('E'+msg.to_json)}
            puts "pumping mtgox #{offers["bids"].size} bids"
            msgs = offers(offers, 'bids')
            msgs.each {|msg| @zpub.write('E'+msg.to_json)}
            puts "pump transfer delay #{Time.now-now}s"
          else
            puts data.inspect
          end
        end
      end

      class Websocket
        include Celluloid::IO

        def websocket_connect
          url = "https://socketio.mtgox.com/mtgox/1"
          result = HTTParty.post url
          puts result.body.inspect

          puts "connecting to websocket"
          s = TCPSocket.new('socketio.mtgox.com',80)
          begin
            handshake = WebSocket::Handshake::Client.new(:url => 'ws://socketio.mtgox.com/mtgox')
            puts handshake.to_s
            s.write handshake.to_s
            puts "reading"
            data = s.readpartial(4096)
            puts "got #{data}"
          rescue EOFError => e
            puts data
            puts e.to_s
          end
        end
      end
    end
  end
end

e1 = Wopr::Exchanges::Mtgox::Rest.new
loop do
  e1.offer_pump
  puts "sleeping 30\n"
  sleep 30
end
#mtgox_ws = Wopr::Exchanges::Mtgox::Websocket.new
#mtgox_ws.async.websocket_connect
e1.run