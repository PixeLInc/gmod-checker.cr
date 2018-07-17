var connected = false;
var ready = false;
var socket = undefined;

var registered = false;

function ws_connect() {
  if (socket !== undefined || connected) return;
  console.log('[WEBSOCKET] Attempting a websocket connect');
  socket = new WebSocket('ws://localhost:7777/api/relay');

  socket.onopen = function(event) {
    connected = true;
    console.log('[WEBSOCKET] Connected.');
  };

  socket.onerror = function(error) {
    console.log('[WEBSOCKET] An error occurred: ' + error);
  };
}

function ws_registerCallback(callback) {
  if (registered) return;
  socket.onmessage = function(event) {
    console.log('[WEBSOCKET] Received: ' + event.data);

    var data = $.parseJSON(event.data);
    callback(data);
  }

  registered = true;
}

function ws_waitForConnection(websocket, callback) {
    setTimeout(
        function() {
            if (socket.readyState === 1) {
                console.log('[WEBSOCKET] Connection ready.');
                if (callback)
                    callback();
            } else {
                console.log('[WEBSOCKET] Waiting for connection to be ready...');
                ws_waitForConnection(websocket, callback);
            }
        }, 5);
}

function ws_send(data) {
  if (socket === undefined && connected)
    return;
  console.log('[WEBSOCKET] Sending: ' + data);

  if (!ready) {
    ws_waitForConnection(socket, function() {
      ready = true;
      socket.send(data);
    });

    return;
  }

  socket.send(data);
}
