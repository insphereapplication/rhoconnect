# a quick and dirty util class for getting data out of redis
require 'ap'
require 'rhosync'

module RedisUtil
  Rhosync::Store.extend(Rhosync)
  Rhosync::Store.db # need to call this to initialize the @db member of Store
  class << self 
    
    def clear_md(model, user)
      Rhosync::Store.put_data("source:application:#{user}:#{model}:md")
    end
    
    def get_md(model, user)
      Rhosync::Store.get_data("source:application:#{user}:#{model}:md")
    end
    
    def get_attribute(model, user, id, attribute)
      md = get_data(model, user)
      ap md
    end
  
    def get_model(model, user, key)
      md = get_md(model, user)
      unless record = md[key]
        raise "No #{model} record with key #{key} found"
      end
      record
    end
  end
end