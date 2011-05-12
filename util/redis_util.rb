# a quick and dirty util class for getting data out of redis
require 'ap'
require 'rhosync'

module RedisUtil
  Rhosync::Store.extend(Rhosync)
  Rhosync::Store.db # need to call this to initialize the @db member of Store
  class << self
    
    def get_md(model, user)
      Rhosync::Store.get_data("source:application:#{user}:#{model}:md")
    end
    
    def get_attribute(model, user, id, attribute)
      md = get_data(model, user)
      ap md
    end
  end
  
  def get_model(model, user, key)
    md = get_md(model, user)
    unless model = md[key]
      raise "No #{model} with key #{key} found"
    end
    model
  end
end