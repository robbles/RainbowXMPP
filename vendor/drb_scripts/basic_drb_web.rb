#!/bin/env ruby -w

##
# This code goes in your Rails application to send XMPP messages via a 
# DRb server.
#
# Initialize the RemoteTopfunkyIM object in environment.rb to keep the
# DRb connection open.
#
# Author: Loki

require 'drb'
require 'yaml'

config = YAML.load_file('config.yml')
to     = config['to']['jid']

# config/environment.rb
DRb.start_service
RemoteTopfunkyIM = DRbObject.new_with_uri "druby://localhost:7777"

# In a model or controller
begin
  RemoteTopfunkyIM.send_message to, "Hello, world! at #{Time.now.utc}"
rescue DRb::DRbConnError => e
  puts "The DRb server could not be contacted"
end
