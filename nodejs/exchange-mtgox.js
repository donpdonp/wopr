var zmq = require('zmq')
  , pub = zmq.socket('pub');
var io = require('socket.io-client')

pub.bindSync('tcp://127.0.0.1:3096');
console.log('zmq pub listening on port 3096');

var mps = 0 // messages per second
var mps_count = 0
var mps_mark = new Date()
var timer_id;

var url = 'https://socketio.mtgox.com/mtgox'

console.log('Connecting to '+url)
conn = io.connect(url);
conn.on('connect', function(){
  console.log('connected.')
  timer_id = setInterval(performance_report, 10000)
})
conn.on('disconnect', function(){
  console.log('disconnected.')
  setInterval(performance_report, 10000)
  clearInterval(timer_id)
})
conn.on('message', function(data) {
  if(data['op'] == 'private') {
    if(data['private'] == 'depth') {
      pub.send('E'+JSON.stringify(wopr_format(data['depth'])))
    }
  }
  mps_count += 1
});

function wopr_format(depth_msg) {
  wopr_msg = {
    exchange: 'mtgox',
    market: depth_msg['currency']+depth_msg['item'],
    bidask: depth_msg['type_str'],
    price: parseInt(depth_msg['price_int']) / 100000,
    quantity: parseInt(depth_msg['total_volume_int']) / 100000000
  }
  return wopr_msg;
}

function performance_report() {
  now = new Date()
  period = ((now - mps_mark)/1000)
  mps = mps_count / period
  report = {exchange: 'mtgox',
                 mps: mps,
              period: period,
               count: mps_count,
                time: new Date()}

  mps_mark = now
  mps_count = 0
  report_json = JSON.stringify(report)
  if (mps > 0) {
    console.log(report_json)
  }
  pub.send('P'+report_json)
}
