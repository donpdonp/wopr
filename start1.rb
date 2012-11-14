require 'json'

BASE_DIR = File.expand_path(File.dirname(__FILE__))
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))

require 'wopr/exchanges/mtgox'
puts "starting mtgox #{SETTINGS}"
e = Wopr::Exchanges::Mtgox.new
e.run