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

pids = {}
Dir[pid_dir+"/*.pid"].each do |pid_filename|
  process_name = File.basename(pid_filename,".pid")
  pids[process_name] = File.read(pid_filename).to_i
end

# Daemon management
if ARGV[0] == 'start'
  if pids["woprd"]
    puts "woprd already running on PID #{woprd_pid}"
  else
    if (pid = fork).nil? # parallel universes start here
      puts "Daemon start #{Process.pid}"
      Process.setsid #unix magic
      File.open(File.join(pid_dir, "woprd.pid"), "w") {|f| f.write Process.pid}
      $0='woprd'
      require 'wopr/woprd'
      Celluloid::ZMQ.init
      wopr = Wopr::Woprd.new
      wopr.zmq_mainloop
    end
  end
elsif ARGV[0] == 'stop'
  if pids["woprd"]
    puts "Stopping #{pids["woprd"]}"
    File.delete(File.join(pid_dir,"woprd.pid"))
    begin
      Process.kill("HUP", pids["woprd"])
    rescue Errno::ESRCH
      puts "Removed stale PID"
    end
  else
    puts "wopr not running"
  end
else
  if pids["woprd"]
    puts "woprd running. pid #{pids["woprd"]}"
  else
    puts <<EOF
$ wopr [start|stop]
EOF
  end
end

