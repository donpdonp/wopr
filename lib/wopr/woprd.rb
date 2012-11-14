require 'bundler/setup'
require 'celluloid/zmq'
require 'json'
require 'rethinkdb'

BASE_DIR = File.expand_path(File.dirname(__FILE__))+"/../../"
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))

Celluloid::ZMQ.init

class Woprd
  include Celluloid::ZMQ
  extend RethinkDB::Shortcuts

  def initialize
    zmq_setup
    db_setup
  end

  def zmq_setup
    @addr = SETTINGS["woprd"]["addr"]
    @zpub = PubSocket.new
    puts SETTINGS.inspect
    @zpub.bind(@addr)

    @zsub = SubSocket.new
    @zsub.connect(@addr)
  end

  def db_setup
    config = SETTINGS["woprd"]["rethinkdb"]
    self.class.r.connect(config["host"],
              config["port"],
              config["db"])
  end

  def run
    loop { handle_message! @zsub.read }
  end

  def handle_message(msg)
    puts "#{@addr}: #{msg}"
  end
end

Woprd.new.run