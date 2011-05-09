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
   
CONFIG = YAML::load_file("#{app_path}/settings/config.yml")



