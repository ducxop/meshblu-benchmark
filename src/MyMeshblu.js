var Meshblu = require('meshblu-xmpp');

var panic = function(error){
  console.error(error.stack);
  //process.exit(1);
}

var mConnect = (conn, config, callback)=>{
  conn = new Meshblu(config);
  // Message handler
//   conn.on('message', function(message){
//     //console.log('Message Received: ', message);
//   });
  conn.connect(function(error){
    if (error) {
      panic(error)
    }
    console.log('Connected!')
    callback(conn)
  })
}
exports.mConnect = mConnect

var mWhoami = (conn, callback)=>{  conn.whoami(function(error, device){
  if (error) {
    panic(error);
  }
  console.log('Whoami: ', device);
  });
  typeof callback === 'function' && callback(conn);
}
exports.mWhoami = mWhoami

// Update a specific device - you can add arbitrary json
var mUpdate = (conn, id, callback)=>{
  conn.update(id, { "$set": {"type": "device:generic"}}, function(error){
    if (error) {
      panic(error);
    }
    console.log('Updated the device');
    typeof callback === 'function' && callback(conn);
  });
}
exports.mUpdate = mUpdate

var mRegister = (conn,callback)=>{
  // Register a new device
  conn.register({"type": "device:generic"}, function(error, device){
    if (error) {
      panic(error);
    }
    console.log('Registered a new Device: ', device);
    typeof callback === 'function' && callback(conn);
  });
}
exports.mRegister = mRegister

var mSent = (conn, id, callback)=>{
  // Send a message
  //var msg = "sent from" + id;
  var message = {
    "devices": [id],
    "payload": "new message from to " + id
  };
  conn.message(message, function(error){
    if (error) {
      panic(error);
    }
    console.log("sent message to " + id);
    typeof callback === 'function' && callback(conn);
  });
}
exports.mSent = mSent

var mSub = (conn, sid, callback)=>{
  // Subscribe to your own messages to enable recieving them
  // conn[id].unsubscribe takes the same arguments
  var subscription = {
    "subscriberUuid" : conn.uuid,
    "emitterUuid": sid,
    "type": 'message.received'
  };
  conn.subscribe(conn.uuid, subscription, function(error, result){
    if (error) {
      panic(error);
    }
    console.log("Subscribe to " + sid, result);
    typeof callback === 'function' && callback(conn);
  });
}
exports.mSub = mSub

var mSearch = (conn, callback)=>{
// Search for devices by a query 
  var query = {"type": "device:generic"}
  conn.searchDevices(conn.uuid, query, function(error, devices){
    if (error) {
      panic(error);
    }
    console.log('Search Devices: ', devices);
    typeof callback === 'function' && callback(conn);
  });
}
exports.mSearch =  mSearch