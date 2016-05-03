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
gem "crypt19-rb"
