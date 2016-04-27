var zmq = require('zmq');
	
var port = 3001;
var sock = zmq.socket('push');	
sock.bindSync('tcp://127.0.0.1:' + port);
console.log('Producer bound to port ' + port);

var json = { msg: "a test" };
sock.send(JSON.stringify(json));
