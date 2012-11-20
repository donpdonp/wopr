require 'celluloid/zmq'
require 'json'

BASE_DIR = File.expand_path(File.dirname(__FILE__)+"/../../")
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))

module Wopr
  module ExchangeActor
    def zmq_setup(pub, sub)
      @addr = SETTINGS["wopr"]["exchange"]["addr"]
      @zpub = pub
      puts "exchange pub on #{@addr}"
      @zpub.bind(@addr)

      @addr = SETTINGS["wopr"]["woprd"]["addr"]
      @zsub = sub
      puts "exchange sub on #{@addr}"
      @zsub.subscribe('W')
      @zsub.connect(@addr)
    end

    def run
      loop { handle_message(@zsub.read) }
    end

    def handle_message(msg)
      puts "#{@addr}: #{msg}"
    end
  end
end