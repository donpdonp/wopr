require 'bundler/setup'
require 'json'

BASE_DIR = File.expand_path(File.dirname(__FILE__))+"/../../"
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))
RUBY = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])

# Temp dir setups
log_dir = File.join(BASE_DIR, "log")
Dir.mkdir(log_dir) unless File.directory?(log_dir)

# Daemon management
if ARGV[0] == 'start'
elsif ARGV[0] == 'quit'
else
  #status
end

