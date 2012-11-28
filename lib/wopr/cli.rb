require 'bundler/setup'
require 'json'
require 'rethinkdb'

BASE_DIR = File.expand_path(File.dirname(__FILE__)+"/../../")
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
  pid = File.read(pid_filename).to_i
  if File.exists?("/proc/#{pid}")
    pids[process_name] = pid
  else
    puts "Clearing stale PID file #{pid_filename}"
    File.delete(pid_filename)
  end
end

# Daemon management
if ARGV[0] == 'start'
  if pids["woprd"]
    puts "woprd already running on PID #{pids["woprd"]}"
  else
    # db connect
    begin
      if (pid = fork).nil? # parallel universes start here
        puts "worpd daemon starting (PID #{Process.pid})"
        Process.setsid #unix magic
        File.open(File.join(pid_dir, "woprd.pid"), "w") {|f| f.write Process.pid}
        $0='woprd'
        puts "Connecting to rethinkdb at #{SETTINGS["wopr"]["rethinkdb"]["host"]}:#{SETTINGS["wopr"]["rethinkdb"]["port"]}"
        RethinkDB::RQL.connect(SETTINGS["wopr"]["rethinkdb"]["host"],
                               SETTINGS["wopr"]["rethinkdb"]["port"])
        require 'wopr/woprd'
        Celluloid::ZMQ.init
        wopr = Wopr::Woprd.new
        wopr.zmq_mainloop
      end
    rescue SocketError => e
      puts "Problem connecting to #{SETTINGS["wopr"]["rethinkdb"]["host"]}: #{e}"
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

