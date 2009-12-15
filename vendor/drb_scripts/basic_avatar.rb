#!/bin/env ruby

##
# Description: Update avatar photo for a Jabber account.

require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/roster'
require 'xmpp4r/vcard'

require 'yaml'

# Jabber::debug = true

config   = YAML.load_file('config.yml')
username = config['from']['jid']
password = config['from']['password']

#########

class Jabber::JID

  ##
  # Convenience method to generate node@domain

  def to_short_s
    s = []
    s << "#@node@" if @node
    s << @domain
    return s.to_s
  end

end

class TurkIM

  def initialize(username, password, config={})
    @config          = config
    @friends_sent_to = []
    @friends_online  = {}
    @mainthread      = Thread.current

    login(username, password)

    setup_avatar

    listen_for_subscription_requests
    listen_for_presence_notifications
    listen_for_messages

    send_initial_presence

    Thread.stop
  end

  def login(username, password)
    @jid    = Jabber::JID.new(username)
    @client = Jabber::Client.new(@jid)
    @client.connect
    @client.auth(password)
  end

  def logout
    @mainthread.wakeup
    @client.close
  end


  def setup_avatar
    if vcard_config = @config['vcard']
      photo = IO::readlines(vcard_config['photo_path']).to_s
      @avatar_hash = Digest::SHA1.hexdigest(photo)
      vcard = Jabber::Vcard::IqVcard.new({
        'NICKNAME' => vcard_config['nickname'],
        'FN' => vcard_config['fn'],
        'URL' => vcard_config['url'],
        'PHOTO/TYPE' => 'image/png',
        'PHOTO/BINVAL' => Base64::encode64(photo)
      })
      Jabber::Vcard::Helper::set(@client, vcard)
    end
  end

  def send_initial_presence
    @client.send(Jabber::Presence.new.set_status("XMPP4R at #{Time.now.utc}"))
  end

  def listen_for_subscription_requests
    @roster   = Jabber::Roster::Helper.new(@client)

    @roster.add_subscription_request_callback do |item, pres|
      if pres.from.domain == @jid.domain
        log "ACCEPTING AUTHORIZATION REQUEST FROM: " + pres.from.to_s
        @roster.accept_subscription(pres.from)
      end
    end
  end

  def listen_for_messages
    @client.add_message_callback do |m|
      if m.type != :error
        if !@friends_sent_to.include?(m.from)
          msg = Jabber::Message.new(m.from, "I am a robot. You are connecting for the first time.")
          msg.type = :chat
          @client.send(msg)
          @friends_sent_to << m.from
        end

        case m.body.to_s
        when 'exit'
          msg      = Jabber::Message.new(m.from, "Exiting ...")
          msg.type = :chat
          @client.send(msg)

          logout

        when /\.png/

          puts "Changing to #{m.body}"
          if vcard_config = @config['vcard']
            photo = IO::readlines(m.body.to_s).to_s
            @avatar_hash = Digest::SHA1.hexdigest(photo)

            Thread.new do
              vcard = Jabber::Vcard::IqVcard.new({
                'NICKNAME' => vcard_config['nickname'],
                'FN' => vcard_config['fn'],
                'URL' => vcard_config['url'],
                'PHOTO/TYPE' => 'image/png',
                'PHOTO/BINVAL' => Base64::encode64(photo)
              })
              Jabber::Vcard::Helper::set(@client, vcard)
            end
            
            presence = Jabber::Presence.new(:chat, "Present with new avatar")
            x = presence.add(REXML::Element.new('x'))
            x.add_namespace 'vcard-temp:x:update'
            x.add(REXML::Element.new('photo')).text = @avatar_hash
            @client.send presence
            
          end

        else
          msg      = Jabber::Message.new(m.from, "You said #{m.body} at #{Time.now.utc}")
          msg.type = :chat
          @client.send(msg)
          puts "RECEIVED: " + m.body.to_s

        end
      else
        log [m.type.to_s, m.body].join(": ")
      end
    end
  end

  ##
  # TODO Do something with the Hash of online friends.

  def listen_for_presence_notifications
    @client.add_presence_callback do |m|
      case m.type
      when nil # status: available
        log "PRESENCE: #{m.from.to_short_s} is online"
        @friends_online[m.from.to_short_s] = true
      when :unavailable
        log "PRESENCE: #{m.from.to_short_s} is offline"
        @friends_online[m.from.to_short_s] = false
      end
    end
  end

  def log(message)
    puts(message) if Jabber::debug
  end

end

TurkIM.new(username, password, config)
