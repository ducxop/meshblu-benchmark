myMesh        = require "./src/MyMeshblu.js"
Meshblu       = require 'meshblu-xmpp'
Benchmark     = require 'simple-benchmark'
Table         = require 'cli-table'
async         = require 'async'
_             = require 'lodash'
commander	  = require 'commander'
http          = require('http')
now           = require 'performance-now'
devices       = require('./300kdevices.json').devices

config = 
    hostname: '192.168.105.222',
    port: 5222,
# config2 =
#     hostname: '192.168.105.221',
#     port: 5222,
#     token: "14fc2e1668410784f75ba8c946e4a4b6cac3989f", 
#     uuid: "037dd8ef-19e7-4b44-8172-f2813f0c245c"
benchmark = {}
conn = {}
nr = 0
n = 0
nS = 0
arr = []
bench = []

myParseInt = (string, defaultValue) ->
  int = parseInt(string, 10)
  if typeof int == 'number'
    int
  else
    defaultValue

#@parseInt = (str) => parseInt str, 10

commander
  .option '-t, --total-times [n]', 'create connection in total times (default to 1)', myParseInt, 1
  .option '-i, --interval [n]', 'create connection with interval between each time(default 5s)', myParseInt, 5
  .option '-n, --number-of-devices [n]', 'number of receiver devices to connect at a time (default to 1000)', myParseInt, 1000
  .option '-s, --step [n]', 'display step (defaults to 500)', myParseInt, 500
  .option '-m, --number-of-msg [n]', 'number of parallel messages (defaults to 1)', myParseInt, 1
  .option '-o, --offset [n]','devices uuid offset value (default to 0)', myParseInt, 0
  .option '-f, --offline'
  .parse process.argv

{totalTimes,interval,numberOfDevices,step,numberOfMsg,offset,offline} = commander
totalTimes = totalTimes
interval = interval*1000
# if totalTimes = 1 
#   interval = 99999999
totalConnection = 0
dConnected = {}
dReceived = {}
dStartR = {}
conn = [] #new Meshblu(config2);

sendMessage = (callback) ->
  console.log 'sending msg...'
  arrDevices = []
  date = new Date()
  for i in [2...numberOfDevices*totalTimes+2]
    arrDevices.push devices[i].uuid
  postData = JSON.stringify
    "targetType":"device"
    "pushProfile":"push profile 1"
    "targets":arrDevices #["1102e314-4417-41e9-9caf-fc0c59004109",]
    "payload":"1"
    "priority":0
    "expirationDate":"2018-12-12 23:59:59"
    "messageID": date.getTime()
    "version":date.getTime()
  options =
    host: '192.168.105.222'
    port: 8080
    path: '/messaging/devices/messages/send/'
    method: 'POST'
    headers: 'Content-Type': 'application/json'
        # 'Content-Length': Buffer.byteLength(postData)
  
  req = http.request options,(res)=>
    console.log 'STATUS:', res.statusCode
    #console.log `HEADERS: ${JSON.stringify(res.headers)}`
    res.setEncoding 'utf8'
    rawData = ''
    res.on 'data', (chunk) => 
      rawData+=chunk
    
    res.on 'end', () => 
      console.log JSON.parse rawData
      typeof callback == 'function' && res.statusCode == 200 && callback()
  
  req.on 'error', (e) =>
    console.error 'problem with request:', e.message

  req.write postData
  req.end()

createConnections = () ->
  if nS>=totalTimes
    return
  else if nS==0
    console.log "connecting "
  for i in [numberOfDevices*nS...numberOfDevices*++nS]
    config.uuid = devices[i+offset+2].uuid
    config.token = devices[i+offset+2].token
    conn[i] = new Meshblu(config)
    conn[i].connect (err)=>
      if ++n%step==0 then console.log "connecting ", n
      totalConnection=n
      #callback()
      #if (n==numberOfDevices+nS) then console.timeEnd 'connect'

createConnection = (dv, callback) =>
  config.uuid = dv.uuid
  config.token = dv.token
  conn[n] = new Meshblu(config)
  conn[n].connect (err)=>
    if ++n%step==0 then console.log "connecting ", n
    callback()

startConnect = () ->
  createConnections()
  # if n<numberOfDevices*totalTimes #totalConnection<numberOfDevices*totalTimes
  #   async.each devices.slice(n,n+numberOfDevices), createConnection, () => 
  #     console.timeEnd 'connect'
  #     totalConnection += numberOfDevices


################# Run Benchmark ####################
dStartC = new Date()
console.time 'connect'
if totalTimes>0 && interval>0
  if totalTimes==1
    intervalObj = setImmediate startConnect
  else    
    intervalObj = setInterval startConnect, interval
  stopConnect = () ->
    console.log totalConnection
    if totalConnection==totalTimes*numberOfDevices
      clearInterval intervalObj
      dConnected = new Date()
      console.log 'start receiving: ~'
      receiving()
      if not offline
        console.log 'start send message'
        sendMessage()      
    else
      setTimeout stopConnect, 1000
  setTimeout stopConnect, totalTimes*interval
#else
#  startConnect()
################# End Benchmark ####################

printResults = (id) => #(error) =>
    #return @die error if error?
    if id?
      elapsedTime = bench[id].elapsed()
      totalmsg = arr[id]
      console.log "Receiving Results - ", id
    else
      elapsedTime = benchmark.elapsed()
      totalmsg = nr
      console.log "Final Results: "
    averagePerSecond = totalmsg / (elapsedTime / 1000)
    #messageLoss = 1 - (_.size(@statusCodes) / (@cycles * @numberOfMessages))

    generalTable = new Table
    generalTable.push
      'total msg receive'    : "#{totalmsg}"
    ,
      'took'                 : "#{elapsedTime}ms"
    ,
      'average per second'   : "#{averagePerSecond}/s"

    percentileTable = new Table
      head: ['10th', '25th', '50th', '75th', '90th']

    percentileTable.push [
        nthPercentile(10, @elapsedTimes2)
        nthPercentile(25, @elapsedTimes2)
        nthPercentile(50, @elapsedTimes2)
        nthPercentile(75, @elapsedTimes2)
        nthPercentile(90, @elapsedTimes2)
        ]

    console.log generalTable.toString()
    #console.log percentileTable.toString()
    
nthPercentile = (percentile, array) =>
    array = _.sortBy array
    index = (percentile / 100) * _.size(array)
    if Math.floor(index) == index
      return (array[index-1] + array[index]) / 2
    return array[Math.floor index]

receiving = ()=>
  totalMsgSend = 0
  for i in [0...totalTimes*numberOfDevices]
    #console.log 'listen from ', conn[i].uuid
    conn[i].on 'message', (message) =>
      #console.log message.data.payload
      if ++nr%(step*numberOfMsg)==0 then console.log 'receiving ', nr
      id = parseInt(message.data.payload)
      unless isNaN id
        if arr[id]?
          #console.log 'id, arr[id] ', id, arr[id]
          if ++arr[id]==totalConnection*numberOfMsg
            printResults(id)
        else
          arr[id]=1
          #console.log 'id, arr[id] new ', id, arr[id]
          bench[id] = new Benchmark label:id
      if nr==1
        totalMsgSend = id
        dStartR = new Date()
        benchmark = new Benchmark label:'total benchmark'
      #console.log nr,numberOfMsg,totalConnection,totalTimes
      if nr==(numberOfMsg*totalConnection*totalMsgSend)
        # for i in [1..totalMsgSend]
        #   console.log('ARR:', i, arr[i])
        dReceived = new Date()
        console.log 'Start Connecting: ', dStartC.toString()
        console.log 'Finish Connecting: ', dConnected.toString()
        if totalMsgSend>1 then printResults()
        console.log 'Received 1st msg: ', dStartR.toString()
        console.log 'Received last msg: ', dReceived.toString()
        process.exit 0  

if process.platform == "win32"
  inf = 
    input: process.stdin
    output: process.stdout
  rl = require "readline"
        .createInterface inf
  rl.on "SIGINT", () => process.emit "SIGINT"

onSigint = () =>
  console.log "Exit on SIGINT"
  process.exit 0

process.on "SIGINT", onSigint
