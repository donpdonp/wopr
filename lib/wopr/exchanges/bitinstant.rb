require 'httparty'
require 'json'
require 'cgi'
require 'xmlrpc/client'

module Wopr
  module Exchanges
    module Bitinstant
      class Rest
        @@rest_url = "https://www.bitinstant.com/api/json/"

        def self.rest_post(path, params)
          puts "POST #{@@rest_url+path}"
          puts params.to_json
          resp = HTTParty.post @@rest_url+path, :format => :json, :body => params.to_json,
                                    :headers => { 'Content-Type' => 'application/json' }
          resp.parsed_response
        end

        def self.rest_get(path, ordered_keys, params)
          puts params.to_json
          ordered_keys.each{|k| path += "/"+CGI.escape(params[k])}
          puts "GET #{@@rest_url+path}"
          resp = HTTParty.get @@rest_url+path, :format => :json
          resp.parsed_response
        end

        def self.fee(pay_method, dest_exchange, amount)
          params = {:pay_method => pay_method,
                    :dest_exchange => dest_exchange,
                    :amount => amount,
                    :currency => 'usd'}
          ordered_keys = [:pay_method, :dest_exchange, :amount, :currency]
          resp = rest_get('CalculateFee', ordered_keys, params)
        end

        def self.quote(pay_method, amount, dest_exchange, dest_account, email)
          #params = [pay_method, amount, dest_exchange, dest_account]
          #resp = @rpc.call('GetQuote', *params)
          params = { :pay_method => pay_method,
                     :amount => amount,
                     :dest_exchange => dest_exchange,
                     :dest_account => dest_account,
                     :notify_email => email }
          resp = rest_post('GetQuote', params)
          puts resp.inspect
        end

        def self.callback(quote_id, url)
          params = {:quote_id => quote_id,
                    :url => url}
          ordered_keys = [:quote_id, :url]
          resp = rest_get('SubscribeEvents', ordered_keys, params)
        end

        def self.order(pay_method, quote_id, code)
          params = {:pay_method => pay_method,
                    :quote_id => quote_id,
                    :code => code}
          resp = rest_post('NewOrder', params)
        end
      end

      class XmlRpc
        @@rpc_url = "https://www.bitinstant.com/api/xmlrpc"
        @@rpc = XMLRPC::Client.new_from_uri @@rpc_url
      end
    end
  end
end
