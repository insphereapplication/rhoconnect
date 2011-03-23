
require 'resque_scheduler'
require "#{File.expand_path(File.join(File.dirname(__FILE__)))}/mappers/mapper"
require "#{File.expand_path(File.join(File.dirname(__FILE__)))}/util/redis_util"
require 'ap'

[
  'lib', 
  'jobs', 
  'api', 
  'initializers', 
  'mappers'
].each do 
   |dir| Dir[File.join(File.dirname(__FILE__),dir,'**','*.rb')].each { |file| require file }
 end
   
CONFIG = YAML::load_file("#{File.expand_path(File.join(File.dirname(__FILE__)))}/settings/config.yml")

Resque.redis = Redis.connect(:url => ENV['REDIS'])
Resque.schedule = YAML.load_file(File.join(File.dirname(__FILE__), 'settings/resque_schedule.yml'))
Resque::Scheduler.run if fork.nil?
Resque::Worker.new('clean_old_opportunity_data').work(1) if fork.nil?






