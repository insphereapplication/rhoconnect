root_path = File.expand_path("#{File.dirname(__FILE__)}/..")
require "#{root_path}/util/insite_logger"
require "#{root_path}/util/exception_util"
require "#{root_path}/util/config_file"

module RhosyncResqueJob
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
    Rhosync::Store.db # need to call this to initialize the @db member of Store
    
    def users
      @redis = Redis.connect(:url => ENV['REDIS'])
      userkeys = @redis.keys('user:*:rho__id')
      userkeys.map{|u| @redis.get(u)}
    end
  end
end