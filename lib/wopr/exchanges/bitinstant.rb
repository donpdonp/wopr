require 'wopr/exchange_actor'

module Wopr
  module Exchanges
    module Bitinstant
      class Rest
        @rest_url = "https://www.bitinstant.com/api/json/"
        @rpc_url = "https://www.bitinstant.com/api/xmlrpc"
        @rpc = XMLRPC::Client.new_from_uri @rpc_url

      end
    end
  end
end
