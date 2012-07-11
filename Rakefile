require 'rubygems'
begin
  require 'vendor/rhoconnect/lib/rhoconnect/tasks'
  require 'vendor/rhoconnect/lib/rhoconnect'
rescue LoadError
  require 'rhoconnect/tasks'
  require 'rhoconnect'
  require 'rhoconnect/server'
end


# ROOT_PATH = File.expand_path(File.dirname(__FILE__))

begin
  require 'resque/tasks'
  require 'resque_scheduler'
  require 'resque/scheduler'
  
  namespace :resque do
    task :setup do
      require 'application'
      Resque.redis = Redis.connect(:url => ENV['REDIS'])
      Resque.schedule = YAML.load_file(File.join(File.dirname(__FILE__), 'settings/resque_schedule.yml'))
    end
    
    task :run_workers do
      Resque::Worker.new('clean_old_opportunity_data').work(1) 
      Resque::Worker.new('limit_client_exceptions').work(1) 
    end
    
    task :scheduler do
      Resque::Scheduler.run
    end
  end
rescue LoadError
  puts "Resque not available. Install it with: "
  puts "gem install resque\n\n"
end

app_path = File.expand_path(File.join(File.dirname(__FILE__)))
require "#{app_path}/util/config_file"
require "#{app_path}/util/rhosync_api_session"
require "#{app_path}/helpers/crypto"

Dir[File.join(File.dirname(__FILE__),'tasks/lib','*.rb')].each { |file| load file }
Dir[File.join(File.dirname(__FILE__),'tasks','*.rb')].each { |file| load file }
