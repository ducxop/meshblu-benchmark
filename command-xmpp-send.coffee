_             = require 'lodash'
commander     = require 'commander'
async         = require 'async'
uuid          = require 'uuid'
colors        = require 'colors'
MeshbluConfig = require 'meshblu-config'
Benchmark     = require 'simple-benchmark'
request       = require 'request'
url           = require 'url'
Table         = require 'cli-table'
MeshbluXmpp   = require 'meshblu-xmpp'

class CommandXmppSend
  parseOptions: =>
    commander
      .option '-c, --cycles [n]', 'number of cycles to run (defaults to 1)', @parseInt, 1
      .option '-n, --number-of-connection [n]', 'Number of parallel connection (defaults to 1000)', @parseInt, 1000
      .option '-s, --step [n]', 'display step', @parseInt, 200
      .parse process.argv

    {@step,@numberOfConnection,@cycles} = commander

  run: ->
    @parseOptions()
    
    @statusCodes = []
    @elapsedTimes = []
    @elapsedTimes2 = []
    @config = 
      hostname: '192.168.105.221'
      port: 5222
      uuid: 'cea58c41-aaa0-46d8-ac9e-2ebc90eeaefe'
      token: 'fc23d79499edec704aa0034538e2b1f588e463ea'
    @config2 = 
      hostname: '192.168.105.221'
      port: 5222
      uuid: 'a1c383b7-931b-4d74-a109-ce57634f6a25'
      token: '6fa96222fd6a0c519ed8c73e053ff36d17e02775'
    @conn = new MeshbluXmpp @config
    @conn.connect (error) =>
      console.log 'Device 1 connected'
    # # # # # # # # # # # # # # # # # # # # # # 
    nr = 0
    @conn2 = new MeshbluXmpp @config2
    @conn2.on 'message', (message) =>
      if ++nr%@step==0 
        console.log 'Receiving ' +nr+ ': '+ message.data.payload
      if nr==1 
        console.log 'Receiving first msg...'
        @benchmark2 = new Benchmark label: 'receive msg'
      @elapsedTimes2.push @benchmark2.elapsed()
      if nr == @cycles * @numberOfConnection *1
        @printResults2()
    # # # # # # # # # # # # # # # # # # # # # # #
    @ns = 0
    @benchmark = new Benchmark label: 'connect'
    async.timesSeries @cycles, @cycle, @printResults

  cycle: (i, callback) =>
    async.times @numberOfConnection, @authenticate, callback

  authenticate: (i, callback) =>  
    benchmark = new Benchmark label: 'sending'
    @conn2.connect (error) =>
      if ++@ns%@step==0 
        console.log 'device 2 connected: ' + @ns
      @elapsedTimes.push benchmark.elapsed()
      if error?
        console.log error.response
        @statusCodes.push 'Error'
      else
        @statusCodes.push 'OK'
      #console.log 'Message ' + i + ' sent'
      callback()    

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

  parseInt: (str) => parseInt str

  xmppsend: () =>
    message = 
          "devices": [@conn2.uuid],
          "payload": "new message from 1"
    @conn.message message, (error) =>  
      if error?
        console.log error.response
      # else
      #   console.log 'msg sent!'

  printResults: () => #(error) =>
    #return @die error if error?
    
    #for num in [5..1]
    async.times 1, @xmppsend
          

    elapsedTime = @benchmark.elapsed()
    averagePerSecond = (_.size @statusCodes) / (elapsedTime / 1000)
    messageLoss = 1 - (_.size(@statusCodes) / (@cycles * @numberOfConnection))

    generalTable = new Table
    generalTable.push
      'total connection'     : "#{@numberOfConnection * @cycles}"
    ,
      'took'                 : "#{elapsedTime}ms"
    ,
      'average per second'   : "#{averagePerSecond}/s"
    ,
      'received status'      : "#{_.uniq @statusCodes}"
    ,
      'send error'           : "#{messageLoss * 100}%"

    percentileTable = new Table
      head: ['10th', '25th', '50th', '75th', '90th']

    percentileTable.push [
      @nthPercentile(10, @elapsedTimes)
      @nthPercentile(25, @elapsedTimes)
      @nthPercentile(50, @elapsedTimes)
      @nthPercentile(75, @elapsedTimes)
      @nthPercentile(90, @elapsedTimes)
    ]

    console.log "Connecting Results:"
    console.log generalTable.toString()
    console.log percentileTable.toString()
    console.log "\n"
    
  printResults2: () => #(error) =>
    elapsedTime = @benchmark2.elapsed()
    averagePerSecond = (@cycles * @numberOfConnection) / (elapsedTime / 1000)

    generalTable = new Table
    generalTable.push
      'total msg receive'    : "#{@numberOfConnection * @cycles}"
    ,
      'took'                 : "#{elapsedTime}ms"
    ,
      'average per second'   : "#{averagePerSecond}/s"

    percentileTable = new Table
      head: ['10th', '25th', '50th', '75th', '90th']

    percentileTable.push [
      @nthPercentile(10, @elapsedTimes2)
      @nthPercentile(25, @elapsedTimes2)
      @nthPercentile(50, @elapsedTimes2)
      @nthPercentile(75, @elapsedTimes2)
      @nthPercentile(90, @elapsedTimes2)
    ]

    console.log "Receiving Results:"
    console.log generalTable.toString()
    console.log percentileTable.toString()
    
    process.exit 0

  nthPercentile: (percentile, array) =>
    array = _.sortBy array
    index = (percentile / 100) * _.size(array)
    if Math.floor(index) == index
      return (array[index-1] + array[index]) / 2

    return array[Math.floor index]

new CommandXmppSend().run()
