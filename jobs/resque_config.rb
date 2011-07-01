root_path = File.expand_path("#{File.dirname(__FILE__)}/..")
require "#{root_path}/util/config_file"
require 'resque_scheduler'
require 'yaml'

Resque.redis = CONFIG[:redis]
Resque.schedule = YAML.load_file("#{root_path}/settings/resque_schedule.yml")