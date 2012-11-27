require 'bundler/setup'
require 'json'

BASE_DIR = File.expand_path(File.dirname(__FILE__))+"/../../"
SETTINGS = JSON.load(File.open(File.join(BASE_DIR,"config/settings.json")))
RUBY = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])

# Temp dir setups
log_dir = File.join(BASE_DIR, "log")
Dir.mkdir(log_dir) unless File.directory?(log_dir)
pid_dir = File.join(BASE_DIR, "tmp/pids")
FileUtils.mkdir_p(pid_dir) unless File.directory?(pid_dir)

woprd_pid_filename = File.join(pid_dir, "woprd.pid")
if File.exists?(woprd_pid_filename)
  woprd_pid= File.read(woprd_pid_filename).to_i
end

# Daemon management
if ARGV[0] == 'start'
  if woprd_pid
    puts "woprd already running on PID #{woprd_pid}"
  else
    if (pid = fork).nil? # parallel universes start here
      puts "Daemon start #{Process.pid}"
      Process.setsid #unix magic
      File.open(File.join(pid_dir, "woprd.pid"), "w") {|f| f.write Process.pid}
      require 'wopr/woprd'
      Celluloid::ZMQ.init
      wopr = Wopr::Woprd.new
      wopr.zmq_mainloop
    end
  end
elsif ARGV[0] == 'stop'
  if woprd_pid
    File.delete(woprd_pid_filename)
    puts "Stopping #{woprd_pid}"
    begin
    Process.kill("HUP", woprd_pid)
    rescue Errno::ESRCH
      puts "Removed stale PID"
    end
  else
    puts "wopr not running"
  end
else
  if woprd_pid
    puts "Status: pid #{woprd_pid}"
  else
    puts <<EOF
Help:
$ wopr [start|stop]
EOF
  end
end

