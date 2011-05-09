require "#{File.expand_path(File.join(File.dirname(__FILE__)))}/mappers/mapper"
require "#{File.expand_path(File.join(File.dirname(__FILE__)))}/util/redis_util"
require "#{File.expand_path(File.join(File.dirname(__FILE__)))}/util/exception_util"
require 'resque_scheduler'
require 'ap'
require 'rhosync'
require 'sinatra'

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



