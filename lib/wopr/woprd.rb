require 'bundler/setup'
require 'celluloid/zmq'
require 'json'
require 'rethinkdb'

BASE_DIR = File.expand_path(File.dirname(__FILE__)+"/../../")
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))

Celluloid::ZMQ.init

module Wopr
  class Woprd
    include Celluloid::ZMQ
    extend RethinkDB::Shortcuts

    def initialize
      zmq_setup
      @rdb_config = SETTINGS["wopr"]["rethinkdb"]
      db_setup
    end

    def zmq_setup
      @addr = SETTINGS["wopr"]["woprd"]["addr"]
      @zpub = PubSocket.new
      puts "woprd pub on #{@addr}"
      @zpub.bind(@addr)

      @addr = SETTINGS["wopr"]["exchange"]["addr"]
      @zsub = SubSocket.new
      puts "woprd sub on #{@addr}"
      @zsub.connect(@addr)
    end

    def db
      self.class.r.db(@rdb_config["db"])
    end

    def db_setup
      self.class.r.connect(@rdb_config["host"], @rdb_config["port"])
      unless self.class.r.db_list.run.include?(@rdb_config["db"])
        self.class.r.db_create(@rdb_config["db"]).run
        puts "Warning: created database #{@rdb_config["db"]}"
      end
      puts "Connected to #{@rdb_config["host"]}:#{@rdb_config["db"]}"

      unless db.table_list.run.include?('exchanges')
        db.table_create('exchanges').run
        puts "Warning: created table 'exchanges'"
      end

      ecount = db.table('exchanges').count.run
      puts "#{ecount} exchanges found"
    end

    def run
      loop { handle_message(@zsub.read) }
    end

    def handle_message(msg)
      puts "#{@addr}: #{msg}"
    end
  end
end

Wopr::Woprd.new.run