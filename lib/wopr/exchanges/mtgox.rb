require 'bundler/setup'
require 'httparty'
require 'celluloid/zmq'
require 'wopr/exchange_actor'
require 'json'

module Wopr
  module Exchanges
    class Mtgox
      include Wopr::ExchangeActor

      def initialize
        zmq_setup
      end

      def depth_poll(conn, from_currency, to_currency)
        # covers two markets, from/to and to/from
        url = "https://mtgox.com/api/1/#{from_currency.upcase}#{to_currency.upcase}/depth"
        JSON.parse(conn.get(url).body)["return"]
      end

      def offers(data, currency)
        if @market.from_currency == currency
          offer_type = "ask"
        else
          offer_type = "bid"
        end
        data[offer_type+"s"].map do |offer|
          { bidask: offer_type,
            listed_at: Time.at(offer["stamp"].to_i/1000000),
            price: offer["price"],
            quantity: offer["amount"],
            currency: currency
          }
        end
      end
    end
  end
end