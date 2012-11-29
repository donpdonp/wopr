require 'celluloid/zmq'
require 'json'

BASE_DIR = File.expand_path(File.dirname(__FILE__)+"/../../")
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))

module Wopr
  module ExchangeActor
    def zmq_setup(pub, sub, class_name)
      puts "Fetching exchange record for #{class_name}"
      me = db.table('exchanges').filter({"name"=>class_name}).run.first
      puts me.inspect
      @zpub = pub
      puts "exchange pub on #{me["zmq_pub"]}"
      @zpub.bind(me["zmq_pub"])

      @addr = SETTINGS["wopr"]["woprd"]["addr"]
      @zsub = sub
      puts "wopr sub on #{@addr}"
      @zsub.subscribe('W')
      @zsub.connect(@addr)
    end

    def db_setup(r)
      rdb_config = SETTINGS["wopr"]["rethinkdb"]
      r.connect(rdb_config["host"], rdb_config["port"])
    end

    def db
      self.class.r.db(SETTINGS["wopr"]["rethinkdb"]["db"])
    end

    def run
      loop { handle_message(@zsub.read) }
    end

    def handle_message(msg)
      puts "#{@addr}: #{msg}"
    end
  end
end