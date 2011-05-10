app_path = File.expand_path(File.join(File.dirname(__FILE__))) 

require "#{app_path}/mappers/mapper"
require "#{app_path}/util/redis_util"
require "#{app_path}/util/exception_util"
require 'resque_scheduler'
require 'ap'
require 'rhosync'
require 'sinatra'

[
  'util',
  'lib', 
  'jobs', 
  'api', 
  'initializers', 
  'mappers'
].each do 
   |dir| Dir[File.join(File.dirname(__FILE__),dir,'**','*.rb')].each { |file| require file }
 end
 
if !!CONFIG[:fork_resque]
  # the following code loads the resque scheduler and worker into forked processes, which is necessary in order to run
  # the nightly data aging cleanup task. 
  Resque.redis = Redis.connect(:url => ENV['REDIS'])
  Resque.schedule = YAML.load_file(File.join(File.dirname(__FILE__), 'settings/resque_schedule.yml'))
  Resque::Scheduler.run if fork.nil?
  Resque::Worker.new('clean_old_opportunity_data').work(1) if fork.nil?
end
   




