require 'rubygems'
require 'bundler/setup'
require 'rhoconnect'
require 'resque/tasks'

ROOT_PATH = File.expand_path(File.dirname(__FILE__))

#task 'resque:setup' do
  # The number of redis connections you want a job to have
#  Rhoconnect.connection_pool_size = 1
#  require 'rhoconnect/application/init'

 # Resque.after_fork do
 #   Store.reconnect
 # end
 #end 
  
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
require "#{app_path}/util/rhoconnect_api_session"
require "#{app_path}/helpers/crypto"

Dir[File.join(File.dirname(__FILE__),'tasks/lib','*.rb')].each { |file| load file }
Dir[File.join(File.dirname(__FILE__),'tasks','*.rb')].each { |file| load file }

