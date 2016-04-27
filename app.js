var fs = require('fs'),
	zmq = require('zmq'),
	spawn = require('child_process').spawn;
	
	
var port = 3001;
var sock = zmq.socket('pull');	
sock.connect('tcp://127.0.0.1:' + port);
console.log('Worker bound to port ' + port);

sock.on('message', function(msg) {
	var m = JSON.parse(msg);
	console.log(m);
});
