commander   = require 'commander'
packageJSON = require './package.json'

class Command
  run: =>
    commander
      .version packageJSON.version
      .command 'xmpp-authen', 'benchmark xmpp authen'
      .command 'xmpp-send', 'benchmark xmpp send msg'
      .command 'xmpp-receive', 'start xmpp a receiver'
      .command 'xmpp-receivers', 'start xmpp receivers'
      .command 'xmpp-msg', 'benchmark xmpp messaging'
      .command 'message-webhook', 'register webhook and benchmark round-trip'
      .command 'authenticate-blast', 'blast the authenticate service'
      .command 'subscription-list', 'benchmark the subscription list'
      .parse process.argv

    unless commander.runningCommand
      commander.outputHelp()
      process.exit 1

(new Command()).run()
