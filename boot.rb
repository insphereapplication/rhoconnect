require 'resque_scheduler'
require 'mappers/mapper'
require 'ap'

['jobs', 'api', 'initializers', 'mappers'].each { |dir| Dir[File.join(File.dirname(__FILE__),dir,'**','*.rb')].each { |file| require file }}
CONFIG = YAML::load_file('settings/config.yml')

Resque.schedule = YAML.load_file(File.join(File.dirname(__FILE__), 'settings/resque_schedule.yml'))



