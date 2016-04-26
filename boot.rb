app_path = File.expand_path(File.join(File.dirname(__FILE__))) 

require "#{app_path}/util/config_file"
require "#{app_path}/mappers/mapper"
require "#{app_path}/push_handlers/push_handler"
require "#{app_path}/util/redis_util"
require "#{app_path}/util/exception_util"
require "#{app_path}/util/update_history_util"
require "#{app_path}/util/update_util"
require "#{app_path}/util/proxy_util"
require "#{app_path}/util/sync_status_util"
require "#{app_path}/helpers/crypto"
require 'resque-scheduler'
require 'ap'
require 'rhoconnect'
require 'sinatra'

[
  'util',
  'lib', 
  'api', 
  'initializers', 
  'mappers',
  'push_handlers'
].each do 
   |dir| Dir[File.join(File.dirname(__FILE__),dir,'**','*.rb')].each { |file| require file }
 end
 
if CONFIG[:fork_resque] && ENV['RHO_ENV'] != 'test'
  # the following code loads the resque scheduler and worker into forked processes, which is necessary in order to run
  # the nightly data aging cleanup task. 
  Resque.redis = Redis.connect(:url => ENV['REDIS'])
  Resque.schedule = YAML.load_file(File.join(File.dirname(__FILE__), 'settings/resque_schedule.yml'))
  Resque::Scheduler.run if fork.nil?
  Resque::Worker.new('clean_old_opportunity_data').work(1) if fork.nil?
end
 




