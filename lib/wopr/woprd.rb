require 'bundler/setup'
require 'celluloid/zmq'
require 'json'

BASE_DIR = File.expand_path(File.dirname(__FILE__))+"/../../"
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))

Celluloid::ZMQ.init

class Woprd
  include Celluloid::ZMQ

  def initialize
    @addr = SETTINGS["woprd"]["addr"]
    @zpub = PubSocket.new
    puts SETTINGS.inspect
    @zpub.bind(@addr)

    @zsub = SubSocket.new
    @zsub.connect(@addr)
  end

  def run
    loop { handle_message! @zsub.read }
  end

  def handle_message(msg)
    puts "#{@addr}: #{msg}"
  end
end

Woprd.new.run