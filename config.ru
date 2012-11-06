#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require "#{File.dirname(__FILE__)}/util/config_file"

if CONFIG[:bundler]
  require 'bundler'
  Bundler.require
end

if CONFIG[:redis_boot]
  ENV['REDIS'] = "redis://#{CONFIG[:redis]}"
end

# This line specifies the section from which the RhoConnect framework will load its settings.
ENV['RACK_ENV'] = CONFIG[:env].to_s

# Try to load vendor-ed rhoconnect otherwise load the gem
begin
  require 'vendor/rhoconnect/lib/rhoconnect/server'
  require 'vendor/rhoconnect/lib/rhoconnect/web-console/server'
  require 'rhoconnect/console/server'
rescue LoadError
  require 'rhoconnect/server'
  require 'rhoconnect/web-console/server'
end

# By default, turn on the resque web console
require 'resque/server'
require 'sinatra'
require 'logger'
require 'ap'

require "#{File.dirname(__FILE__)}/util/insite_logger"
require "#{File.dirname(__FILE__)}/util/insite_rack_logger"
require "#{File.dirname(__FILE__)}/util/insite_rhosync_logger"

use Rack::CommonLogger, InsiteRackLogger.new

set :raise_errors, true

ROOT_PATH = File.expand_path(File.dirname(__FILE__))

# Rhoconnect server flags
# Rhoconnect::Server.enable  :stats
Rhoconnect::Server.disable :run
Rhoconnect::Server.disable :clean_trace
Rhoconnect::Server.enable  :raise_errors

Rhoconnect::Server.set     :secret,      '8b885f195f8561e9738cec8f1e280af467722366a28128af0a61310eeeb23d5e1c59b1726711ca2e87ebc744781a4e7c47c7b52697f6d80c52f49a8152b0a7ab'
Rhoconnect::Server.set     :root,        ROOT_PATH
Rhoconnect::Server.use     Rack::Static, :urls => ["/data"], :root => Rhoconnect::Server.root
EventMachine.threadpool_size = 4 # default is 20

# Force SSL
if CONFIG[:ssl]
  require 'rack/ssl-enforcer'
  Rhoconnect::Server.use         Rack::SslEnforcer
  RhoconnectConsole::Server.use  Rack::SslEnforcer
  Resque::Server.use          Rack::SslEnforcer
end

# disable Async mode if Debugger is used
#  Rhoconnect::Server.set :use_async_model, false


# Load our rhoconnect application
require './application'

# Setup the url map
run Rack::URLMap.new \
	"/"         => Rhoconnect::Server.new,
	"/console"  => RhoconnectConsole::Server.new # If you don't want rhoconnect frontend, disable it here
	
InsiteLogger.info(:format_and_join => ["Rhoconnect.environment after bootstrap: #{Rhoconnect.environment}, CONFIG: ",CONFIG])
