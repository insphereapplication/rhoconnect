#!/usr/bin/env ruby

# Try to load vendor-ed rhosync, otherwise load the gem
begin
  require 'vendor/rhosync/lib/rhosync/server'
  require 'vendor/rhosync/lib/rhosync/console/server'
rescue LoadError
  require 'rhosync/server'
  require 'rhosync/console/server'
end

# By default, turn on the resque web console
require 'resque/server'
require 'sinatra'

# Library for forcing SSL
require 'rack/ssl-enforcer'

set :raise_errors, true

ROOT_PATH = File.expand_path(File.dirname(__FILE__))

# Rhosync server flags
Rhosync::Server.enable  :stats
Rhosync::Server.disable :run
Rhosync::Server.disable :clean_trace
Rhosync::Server.enable  :raise_errors
Rhosync::Server.set     :environment, :production
Rhosync::Server.set     :secret,      '8b885f195f8561e9738cec8f1e280af467722366a28128af0a61310eeeb23d5e1c59b1726711ca2e87ebc744781a4e7c47c7b52697f6d80c52f49a8152b0a7ab'
Rhosync::Server.set     :root,        ROOT_PATH
Rhosync::Server.use     Rack::Static, :urls => ["/data"], :root => Rhosync::Server.root

# Force SSL
Rhosync::Server.use     Rack::SslEnforcer

# Load our rhosync application
require 'application'

# Setup the url map
run Rack::URLMap.new \
	"/"         => Rhosync::Server.new,
	"/resque"   => Resque::Server.new, # If you don't want resque frontend, disable it here
	"/console"  => RhosyncConsole::Server.new # If you don't want rhosync frontend, disable it here
	
