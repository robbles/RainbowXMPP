#!/bin/env ruby

##
# Simple IM client that announces status.

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

Thread.stop
client.close
