require 'bundler/setup'
require 'celluloid/zmq'
require 'json'

BASE_DIR = File.expand_path(File.dirname(__FILE__))
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))

Celluloid::ZMQ.init

class Zmqtalk
  include Celluloid::ZMQ

  def initialize
    @addr = SETTINGS["wopr"]["woprd"]["addr"]

    @zpub = PubSocket.new
    puts "Connecting new Publisher to #{@addr}"
    @zpub.bind(@addr)
  end

  def write(msg)
    puts "sending to #{@addr}: #{msg}"
    @zpub.write(msg)
  end
end

z = Zmqtalk.new
i=0
loop do
  i+=1
  sleep 1
  z.write("E "+ARGV[0]+" #{i}")
end