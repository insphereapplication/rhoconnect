require File.expand_path("#{File.dirname(__FILE__)}/../initializers/hash_extension")
require 'yaml'

class ConfigFile
  def self.load
    settings = YAML::load_file("#{File.dirname(__FILE__)}/../settings/settings.yml")
    env = settings[:env].to_sym
	debug = settings[:debug]
    get_settings_for_environment(settings, env, debug)
	
  end
  
  def self.get_settings_for_environment(settings_yaml, env, debug = false)
    # load and merge all global and env-specific settings from the given settings yml
    config = settings_yaml[:global].deep_merge(settings_yaml[env])
    config[:crm_path] = settings_yaml[config[:crm_proxy]]
    config[:env] = env
	config[:debug] = debug
    config[:sources] = settings_yaml[:sources]
    config[:redis_url], config[:redis_port] = config[:redis].split(':')
    config
  end
end

CONFIG = ConfigFile.load unless defined?(CONFIG)
