require 'bundler/setup'
require 'json'
require 'wopr/woprd'

BASE_DIR = File.expand_path(File.dirname(__FILE__))+"/../../"
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))
RUBY = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])

# Temp dir setups
log_dir = File.join(BASE_DIR, "log")
Dir.mkdir(log_dir) unless File.directory?(log_dir)
pid_dir = File.join(BASE_DIR, "pid")
Dir.mkdir(pid_dir) unless File.directory?(pid_dir)

# Daemon management
if ARGV[0] == 'start'

  if (pid = fork).nil? # alternate universes here
    puts "Daemon start #{Process.pid}"
    Process.setsid #unix magic
    File.open(File.join(pid_dir, "woprd.pid"), "w") {|f| f.write Process.pid}
    Celluloid::ZMQ.init
    wopr = Wopr::Woprd.new
    wopr.zmq_mainloop
  end

elsif ARGV[0] == 'stop'
  woprd_pid_filename = File.join(pid_dir, "woprd.pid")
  begin
    pid = File.read(woprd_pid_filename).to_i
    File.delete(woprd_pid_filename)
    puts "Stopping #{pid}"
    begin
    Process.kill("HUP", pid)
    rescue Errno::ESRCH
      puts "Removed stale PID"
    end
  rescue Errno::ENOENT
    puts "wopr not running"
  end
else
  puts "Status"
end

