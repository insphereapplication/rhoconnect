require File.expand_path("#{File.dirname(__FILE__)}/../initializers/hash_extension")

class ConfigFile
  def self.load
    # load and merge all global and env-specific settings from settings.yml
    settings = YAML::load_file("#{File.dirname(__FILE__)}/../settings/settings.yml")
    env = settings[:env].to_sym
    config = settings[:global].deep_merge(settings[env])
    config[:crm_path] = settings[config[:crm_proxy]]
    config[:env] = env
    config[:sources] = settings[:sources]
    config
  end
end

CONFIG = ConfigFile.load unless defined?(CONFIG)
