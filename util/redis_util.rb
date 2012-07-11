# a quick and dirty util class for getting data out of redis
require 'ap'
require 'rhoconnect'

module RedisUtil
  class RecordNotFound < RuntimeError; end
  
  # Rhoconnect::Store.extend(Rhoconnect)
  # Rhoconnect::Store.db # need to call this to initialize the @db member of Store
  class << self
    
    def connect(host, port)
      Rhoconnect::Store.db.client.disconnect if defined?(Rhoconnect::Store.db.client)
      puts "Connecting to redis at #{host}:#{port}"
      Rhoconnect::Store.db = Redis.new(:thread_safe => true, :host => host, :port => port)
    end
    
    def clear_md(model, user)
      Rhoconnect::Store.put_data("source:application:#{user}:#{model}:md")
    end
    
    def get_md(model, user)
      Rhoconnect::Store.get_data("source:application:#{user}:#{model}:md")
    end
    
    def get_attribute(model, user, id, attribute)
      md = get_data(model, user)
      ap md
    end
    
    def get_keys(keymask)
      Rhoconnect::Store.get_keys("#{keymask}*")
    end
    
    def get_value(key)
      Rhoconnect::Store.get_value(key)
    end
  
    def get_model(model, user, key)
      md = get_md(model, user)
      unless record = md[key]
        raise RecordNotFound, "No #{model} record with key #{key} found"
      end
      record
    end
  end
end