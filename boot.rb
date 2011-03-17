require 'resque_scheduler'
require 'mappers/mapper'
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
   
CONFIG = YAML::load_file('settings/config.yml')

Resque.schedule = YAML.load_file(File.join(File.dirname(__FILE__), 'settings/resque_schedule.yml'))
Resque::Worker.new('clean_old_opportunity_data').work if fork.nil? 




