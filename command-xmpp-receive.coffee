myMesh = require "./src/MyMeshblu.js"
Meshblu = require 'meshblu-xmpp'
Benchmark     = require 'simple-benchmark'
Table         = require 'cli-table'
async         = require 'async'
_             = require 'lodash'
commander			= require 'commander'

config = 
    hostname: '192.168.105.221',
    port: 5222,
    uuid: 'cea58c41-aaa0-46d8-ac9e-2ebc90eeaefe',
    token: 'fc23d79499edec704aa0034538e2b1f588e463ea'

config2 =
    hostname: '192.168.105.221',
    port: 5222,
    uuid: 'a1c383b7-931b-4d74-a109-ce57634f6a25',
    token: '6fa96222fd6a0c519ed8c73e053ff36d17e02775'
benchmark = {}
conn = {}
nr = 0
n = 0

myParseInt = (string, defaultValue) ->
  int = parseInt(string, 10)
  if typeof int == 'number'
    int
  else
    defaultValue

@parseInt = (str) => parseInt str, 10

commander
	.option '-n, --number-of-connection [n]', 'number of connection (default to 5000)', @parseInt, 5000
	.option '-s, --step [n]', 'display step (defaults to 1000)', @parseInt, 1000
	.option '-m, --number-of-msg [n]', 'number of parallel messages (defaults to 5000)', @parseInt, 5000
	.parse process.argv

{numberOfConnection,step,numberOfMsg} = commander

conn = new Meshblu(config2);

createConnection = (i, callback) ->
	myMesh.mConnect conn, config2, (conn)=>
		if ++n%step==0 then console.log "connecting ", n
		console.log 'start connecting:' if n == 1
  callback()

async.times numberOfConnection, createConnection, () => 
#async.times 1000, createConnection, () => 
	console.log 'start receiving:'

conn.on 'message', (message) =>
	console.log 'receiving ', nr if ++nr%(step*numberOfMsg)==0
	benchmark = new Benchmark label: 'receive msg' if nr == 1
	#console.log 'Message Received: ', message.data.payload
	printResults() if nr == numberOfMsg * numberOfConnection

printResults = () => #(error) =>
    #return @die error if error?
    elapsedTime = benchmark.elapsed()
    averagePerSecond = n / (elapsedTime / 1000)
    #messageLoss = 1 - (_.size(@statusCodes) / (@cycles * @numberOfMessages))

    generalTable = new Table
    generalTable.push
      'total msg receive'    : "#{n}"
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

    console.log "Receiving Results:"
    console.log generalTable.toString()
    #console.log percentileTable.toString()
    
    process.exit 0

nthPercentile = (percentile, array) =>
    array = _.sortBy array
    index = (percentile / 100) * _.size(array)
    if Math.floor(index) == index
      return (array[index-1] + array[index]) / 2

    return array[Math.floor index]