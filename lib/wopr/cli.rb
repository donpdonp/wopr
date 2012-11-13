require 'bundler/setup'
require 'bluepill'
require 'json'

BASE_DIR = File.expand_path(File.dirname(__FILE__))+"/../../"
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))
RUBY = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])

# Log file
log_dir = File.join(BASE_DIR, "log")
Dir.mkdir(log_dir) unless File.directory?(log_dir)

# Bluepill
Opts = {:base_dir => File.join(BASE_DIR,".bluepill"),
        :log_file => File.join(log_dir,"bluepill")}
bluepill = Bluepill::Controller.new(Opts)
running = bluepill.running_applications.include?('wopr')

# Daemon management
if ARGV[0] == 'start'
  unless running
    eval(File.read("config/blue.pill"))
  end
  bluepill.handle_command('wopr', 'start', ARGV[1])
end

if ARGV[0] == 'quit'
  if running
    bluepill.handle_command('wopr', 'stop')
    bluepill.handle_command('wopr', 'quit')
  else
    puts "Not running"
  end
end
