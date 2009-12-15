#!/bin/env ruby

##
# Simple IM client that sends a message.


require 'rubygems'
require 'xmpp4r'
require 'yaml'

# Jabber::debug = true

config   = YAML.load_file('config.yml')
username = config['from']['jid']
password = config['from']['password']

#########

jid    = Jabber::JID.new(username)
client = Jabber::Client.new(jid)
client.connect
client.auth(password)

mainthread = Thread.current

# Initial presence
client.send(Jabber::Presence.new.set_status("XMPP4R at #{Time.now.utc}"))

msg      = Jabber::Message.new(config['to']['jid'], "Hello, world")
msg.type = :chat
client.send(msg)

Thread.stop
client.close
