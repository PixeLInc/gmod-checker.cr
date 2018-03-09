var connected = false;
var socket = undefined;

function connect() {
  socket = new WebSocket('ws://localhost:7777/ws');

  socket.onopen = function(event) {
    connected = true;
    console.log('[WEBSOCKET] Connected.');
  };

  socket.onerror = function(error) {
    console.log('[WEBSOCKET] An error occurred: ' + error);
  };
}

function registerCallback(callback) {
  socket.onmessage = function(event) {
    console.log(event.data);

    var data = $.parseJSON(event.data);
    callback(data);
  }
}

function send_ws(data) {
  if (socket === undefined && connected)
    return;

  socket.send(data);
}
