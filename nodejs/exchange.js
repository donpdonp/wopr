var zmq = require('zmq')
  , pub = zmq.socket('pub');
var io = require('socket.io-client')

pub.bindSync('tcp://127.0.0.1:3096');
console.log('Producer bound to port 3096');

conn = io.connect('https://socketio.mtgox.com/mtgox');
conn.on('message', function(data) {
  console.log(data)
  pub.send('E'+JSON.stringify(data))
});
