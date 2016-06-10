# config.ru file
require 'rubygems'

#!/usr/bin/env ruby
require "#{File.dirname(__FILE__)}/util/config_file"

# This line specifies the section from which the RhoConnect framework will load its settings.
ENV['RACK_ENV'] = CONFIG[:env].to_s
ENV['DEBUG'] = CONFIG[:debug].to_s

require 'rhoconnect/application/init'

require 'rhoconnect/server'
require 'rhoconnect/web-console/server'

# By default, turn on the resque web console
require 'resque/server'
require 'resque-scheduler'
require 'resque/scheduler/server'
require 'sinatra'
require 'logger'
require 'ap'

require "#{File.dirname(__FILE__)}/util/insite_logger"
require "#{File.dirname(__FILE__)}/util/insite_rack_logger"
require "#{File.dirname(__FILE__)}/util/insite_rhosync_logger"

use Rack::CommonLogger, InsiteRackLogger.new

set :raise_errors, true


# Rhoconnect server flags
# Rhoconnect::Server.enable  :stats
Rhoconnect::Server.disable :run
Rhoconnect::Server.disable :clean_trace
Rhoconnect::Server.enable  :raise_errors

Rhoconnect::Server.set     :secret,      '8b885f195f8561e9738cec8f1e280af467722366a28128af0a61310eeeb23d5e1c59b1726711ca2e87ebc744781a4e7c47c7b52697f6d80c52f49a8152b0a7ab'
#Rhoconnect::Server.set     :root,        ROOT_PATH

# Are the commands below still needed after upgrade?
#Rhoconnect::Server.use     Rack::Static, :urls => ["/data"], :root => Rhoconnect::Server.root
#EventMachine.threadpool_size = 4 # default is 20

# Force SSL

if CONFIG[:ssl]
  require 'rack/ssl-enforcer'
  Rhoconnect::Server.use         Rack::SslEnforcer
  RhoconnectConsole::Server.use  Rack::SslEnforcer
  Resque::Server.use          Rack::SslEnforcer
end

# disable Async mode if Debugger is used
#  Rhoconnect::Server.set :use_async_model, false


# Load our rhoconnect application,  I don't below this is needed after upgrade
#require './application'

# Setup the url map.  Is this needed after upgrade?
#run Rack::URLMap.new \
#	"/"         => Rhoconnect::Server.new,
#	"/console"  => RhoconnectConsole::Server.new # If you don't want rhoconnect frontend, disable it here
	
#InsiteLogger.info(:format_and_join => ["Rhoconnect.environment after bootstrap: #{Rhoconnect.environment}, CONFIG: ",CONFIG])


# secret is generated along with the app
# NOTE:
# Substitute 'REPLACE_ME' string by the Rhoconnect::Server.set :secret value from your old config.ru
#Rhoconnect::Server.set     :secret, '8b885f195f8561e9738cec8f1e280af467722366a28128af0a61310eeeb23d5e1c59b1726711ca2e87ebc744781a4e7c47c7b52697f6d80c52f49a8152b0a7ab'

# !!! Add your custom initializers and overrides here !!!
# For example, uncomment the following line to enable Stats
#Rhoconnect::Server.enable  :stats
# uncomment the following line to disable Resque Front-end console
#Rhoconnect.disable_resque_console = true
# uncomment the following line to disable Rhoconnect Front-end console
#Rhoconnect.disable_rc_console = true

# run RhoConnect Application
run Rhoconnect.app