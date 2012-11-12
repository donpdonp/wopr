require 'bundler/setup'
require 'bluepill'
require 'json'

BASE_DIR = File.expand_path(File.dirname(__FILE__))+"/../../"
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))

opts = {:base_dir => File.join(BASE_DIR,".bluepill")}
bluepill = Bluepill::Controller.new(opts)
