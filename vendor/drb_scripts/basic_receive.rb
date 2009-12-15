#!/bin/env ruby

##
# Simple IM client that receives a message.

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

sent = []

mainthread = Thread.current

# Initial presence
client.send(Jabber::Presence.new.set_status("XMPP4R at #{Time.now.utc}"))

client.add_message_callback do |m|
  if m.type != :error
    if !sent.include?(m.from)
      msg = Jabber::Message.new(m.from, "I am a robot. You are connecting for the first time.")
      msg.type = :chat
      client.send(msg)
      sent << m.from
    end

    case m.body
    when 'exit'
      msg      = Jabber::Message.new(m.from, "Exiting ...")
      msg.type = :chat
      client.send(msg)
      mainthread.wakeup

    else
      msg      = Jabber::Message.new(m.from, "You said #{m.body} at #{Time.now.utc}")
      msg.type = :chat
      client.send(msg)
      puts "Received: " + m.body

    end
  else
    puts [m.type.to_s, m.body].join(": ")
  end
end

Thread.stop
client.close
