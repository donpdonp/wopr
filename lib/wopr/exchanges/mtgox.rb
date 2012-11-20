require 'bundler/setup'
require 'httparty'
require 'wopr/exchange_actor'
require 'json'
require 'faraday'

module Wopr
  module Exchanges
    class Mtgox
      include Celluloid::ZMQ
      include Wopr::ExchangeActor

      def initialize
        zmq_setup(PubSocket.new, SubSocket.new)
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
  end
end

e1 = Wopr::Exchanges::Mtgox.new
e1.async.offer_pump
e1.run