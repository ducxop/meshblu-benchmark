myMesh = require "./src/MyMeshblu.js"
Meshblu = require 'meshblu-xmpp'
Benchmark     = require 'simple-benchmark'
Table         = require 'cli-table'
async         = require 'async'
_             = require 'lodash'
commander			= require 'commander'
now        = require 'performance-now'

config = 
    hostname: '192.168.105.222',
    port: 5222,
    uuid: 'cea58c41-aaa0-46d8-ac9e-2ebc90eeaefe',
    token: 'fc23d79499edec704aa0034538e2b1f588e463ea'

config2 =
    hostname: '192.168.105.222',
    port: 5222,
    uuid: 'a1c383b7-931b-4d74-a109-ce57634f6a25',
    token: '6fa96222fd6a0c519ed8c73e053ff36d17e02775'
benchmark = {}
conn = {}
nr = 0
n = 0
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
  .option '-t, --total-times [n]', 'create connection in total times (default to 0)', myParseInt, 0
  .option '-i, --interval [n]', 'create connection with interval between each time(default 10s)', myParseInt, 10
	.option '-n, --number-of-connection [n]', 'number of connection at a time (default to 5000)', myParseInt, 5000
	.option '-s, --step [n]', 'display step (defaults to 1000)', myParseInt, 1000
	.option '-m, --number-of-msg [n]', 'number of parallel messages (defaults to 1)', myParseInt, 1
	.parse process.argv

{totalTimes,interval,numberOfConnection,step,numberOfMsg} = commander
totalTimes = totalTimes
interval = interval*1000
totalConnection = 0
dConnected = {}
dReceived = {}
dStartR = {}
conn = new Meshblu(config2);

createConnection = (i, callback) ->
	myMesh.mConnect conn, config2, (conn)=>
		if ++n%step==0 then console.log "connecting ", n
		console.log 'start connecting:' if n == 1
  callback()

startConnect = () ->
  if totalConnection<numberOfConnection*totalTimes
    async.times numberOfConnection, createConnection, () => 
      #console.log 'start receiving:'
      totalConnection += numberOfConnection
      #console.log totalConnection, ' connected!'
dStartC = new Date()

if totalTimes>0 && interval>0
  intervalObj = setInterval startConnect, interval
  stopConnect = () ->
    if totalConnection==totalTimes*numberOfConnection
      clearInterval intervalObj
      dConnected = new Date()
      console.log 'start receiving: ~'
    else
      setTimeout stopConnect, 500
  setTimeout stopConnect, totalTimes*interval
else
  startConnect()hy8u jm9ikp

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

totalMsgSend = 0
conn.on 'message', (message) =>
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
    dReceived = new Date()
    console.log 'Start Connecting: ', dStartC.toString()
    console.log 'Finish Connecting: ', dConnected.toString()
    printResults()
    console.log 'Received 1st msg: ', dStartR.toString()
    console.log 'Received last msg: ', dReceived.toString()
    process.exit 0  
	