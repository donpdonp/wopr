module Wopr
  module ExchangeActor
    include Celluloid::ZMQ

    def zmq_setup
      @addr = SETTINGS["wopr"]["exchange"]["addr"]
      @zpub = PubSocket.new
      puts "exchange pub on #{@addr}"
      @zpub.bind(@addr)

      @addr = SETTINGS["wopr"]["woprd"]["addr"]
      @zsub = SubSocket.new
      puts "exchange sub on #{@addr}"
      @zsub.connect(@addr)
    end

    def run
      loop { handle_message! @zsub.read }
    end

    def handle_message(msg)
      puts "#{@addr}: #{msg}"
    end
  end
end