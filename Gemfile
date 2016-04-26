source 'http://rubygems.org'

gem 'rhoconnect', '5.4.0'

gemfile_path = File.join(File.dirname(__FILE__), ".rcgemfile")
begin
  eval(IO.read(gemfile_path))
rescue Exception => e
  puts "ERROR: Couldn't read RhoConnect .rcgemfile"
  exit 1
end

# Add your application specific gems after this line ...
gem "faker"
gem "awesome_print"
gem "exceptional"
gem "resque"
gem "resque-scheduler"
#gem "SystemTimer"
gem "crypt19-rb"
#gem "rack-ssl-enforcer"
# Include mogrel gem for local
#gem "mongrel"
#gem "connection_pool"
#gem "rhoconnect" , "5.4.0"
#gem "sqlite3"
#gem "thin"
#gem 'rack-fiber_pool'
#gem 'async-rack'