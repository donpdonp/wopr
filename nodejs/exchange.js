var zmq = require('zmq')
  , pub = zmq.socket('pub');
var io = require('socket.io-client')

pub.bindSync('tcp://127.0.0.1:3096');
console.log('zmq pub listening on port 3096');

var mps = 0 // messages per second
var mps_count = 0
var mps_mark = new Date()

var url = 'https://socketio.mtgox.com/mtgox'

console.log('Connecting to '+url)
conn = io.connect(url);
conn.on('connection', function(){
  console.log('connected.')
  setInterval(performance_report, 10000)
})
conn.on('message', function(data) {
  pub.send('E'+JSON.stringify(wopr_format(data)))
  mps_count += 1
});

function wopr_format(msg) {
  msg;
}

function performance_report() {
  now = new Date()
  period = ((now - mps_mark)/1000)
  mps = mps_count / period
  mps_mark = now

  report = {mps: mps, period: period, count: mps_count}
  report_json = JSON.stringify(report)
  if (mps > 0) {
    console.log(report_json)
  }
  pub.send('P'+report_json)
}
