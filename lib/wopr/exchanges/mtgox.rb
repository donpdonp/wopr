require 'bundler/setup'
require 'httparty'
require 'wopr/exchange_actor'
require 'json'
require 'faraday'
require 'rethinkdb'
require 'celluloid/io'
require 'websocket'

module Wopr
  module Exchanges
    module Mtgox
      class Rest
        include Celluloid::ZMQ
        include Wopr::ExchangeActor
        extend RethinkDB::Shortcuts

        def initialize
          db_setup(self.class.r)
          zmq_setup(PubSocket.new, SubSocket.new, "Mtgox")
        end

        def depth_poll(conn, from_currency, to_currency)
          # covers two markets, from/to and to/from
          url = "https://mtgox.com/api/1/#{from_currency.upcase}#{to_currency.upcase}/depth"
          JSON.parse(conn.get(url).body)["return"]
        end

        def offers(data, bidask)
          msgs = data[bidask].map do |offer|
            { bidask: 'ask',
              listed_at: Time.at(offer["stamp"].to_i/1000000),
              price: offer["price"],
              quantity: offer["amount"],
              currency: 'usd'
            }
          end
          msgs.each {|msg| @zpub.write('E'+msg.to_json)}
        end

        def offer_pump
          net = Faraday.new(request:{timeout:10})
          puts "mtgox http"
          data = depth_poll(net, 'btc', 'usd')
          puts "mtgox pump #{data["asks"].size}"
          offers(data, 'asks')
        end
      end

      class Websocket
        include Celluloid::IO

        def websocket_connect
          puts "connecting to websocket"
          #https://socketio.mtgox.com/mtgox
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
#e1.async.offer_pump
mtgox_ws = Wopr::Exchanges::Mtgox::Websocket.new
mtgox_ws.async.websocket_connect
e1.run