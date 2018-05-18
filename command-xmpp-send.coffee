_             = require 'lodash'
commander     = require 'commander'
async         = require 'async'
colors        = require 'colors'
MeshbluConfig = require 'meshblu-config'
Benchmark     = require 'simple-benchmark'
Table         = require 'cli-table'
MeshbluXmpp   = require 'meshblu-xmpp'

class CommandXmppSend
  parseOptions: =>
    commander
      .option '-t, --total-times [n]', 'create connection in total time (default to 1)', @parseInt, 1
      .option '-i, --interval [n]', 'create connection with interval (default 10)', @parseInt, 10
      .option '-n, --number-of-connection [n]', 'Number of parallel connections (defaults to 1000)', @parseInt, 1000
      .option '-s, --step [n]', 'display step (defaults to 200)', @parseInt, 200
      .option '-m, --number-of-msg [n]', 'number of parallel messages (defaults to 1)', @parseInt, 1
      .option '-o, --only-send'
      .option '-a, --all'
      .parse process.argv

    {@totalTimes,@interval,@step,@numberOfConnection,@onlySend,@numberOfMsg,@all} = commander

  run: ->
    @parseOptions()
    @interval = @interval * 1000
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
    msg = @totalTimes
    @message = 
      devices: [@config2.uuid],
      payload: msg
    if @onlySend or @all
      console.log 'Sending msg...'
      if @all
        @config.token = "14fc2e1668410784f75ba8c946e4a4b6cac3989f"
        @config.uuid= "037dd8ef-19e7-4b44-8172-f2813f0c245c"
        @message.devices=["*"]
      @conn = new MeshbluXmpp @config
      @conn.connect (error) =>
        console.log 'connectedddd'
        if @totalTimes>1&&@interval>0
          sendMsg = () =>
            if msg>0
              @message.payload = msg
              async.times @numberOfMsg, @xmppsend, () => msg--
          intervalObj = setInterval sendMsg, @interval
          stopSend = () =>
            if msg<1
              clearInterval(intervalObj)
              process.exit 0
            else
              setTimeout stopSend, 500
          setTimeout stopSend, @totalTimes*@interval
        else
          async.times @numberOfMsg, @xmppsend, () => process.exit 0
    else
    # # # # # # # # # # # # # # # # # # # # # # 
      nr = 0
      @conn2 = new MeshbluXmpp @config2
      @conn2.on 'message', (message) =>
        if ++nr%(@step*@numberOfMsg)==0 
          console.log 'Receiving ' +nr+ ': '+ message.data.payload
        if nr==1 
          console.log 'Receiving first msg...'
          @benchmark2 = new Benchmark label: 'receive msg'
        @elapsedTimes2.push @benchmark2.elapsed()
        if nr == @numberOfConnection * @numberOfMsg
          @printResults2()
      # # # # # # # # # # # # # # # # # # # # # # #
      @ns = 0
      @benchmark = new Benchmark label: 'connect'
  #     async.timesSeries @cycles, @cycle, @printResults
  # cycle: (i, callback) =>
      async.times @numberOfConnection, @authenticate, @printResults

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

  xmppsend: (i, callback) =>
    console.log @conn.uuid, @message
    @conn.message @message, (error) =>  
      if error?
        console.log error.response
      callback()
      # else

  printResults: () => #(error) =>
    #return @die error if error?
    @conn = new MeshbluXmpp @config
    @conn.connect (error) =>
      #for num in [5..1]
      # if @onlySend
      async.times @numberOfMsg, @xmppsend
      # else
      #   @xmppsend()          

    elapsedTime = @benchmark.elapsed()
    averagePerSecond = (_.size @statusCodes) / (elapsedTime / 1000)
    messageLoss = 1 - (_.size(@statusCodes) / (@numberOfConnection))

    generalTable = new Table
    generalTable.push
      'total connection'     : "#{@numberOfConnection}"
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
    averagePerSecond = (@numberOfConnection * @numberOfMsg) / (elapsedTime / 1000)

    generalTable = new Table
    generalTable.push
      'total msg receive'    : "#{@numberOfConnection * @numberOfMsg}"
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
