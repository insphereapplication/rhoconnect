root_path = File.expand_path("#{File.dirname(__FILE__)}/..")
require "#{root_path}/util/insite_logger"
require "#{root_path}/util/exception_util"
require "#{root_path}/util/config_file"

module RhosyncResqueJob      
  Rhosync::Store.db # need to call this to initialize the @db member of Store
  
  def users
    @redis = Redis.connect(:host => CONFIG[:redis_url], :port => CONFIG[:redis_port])
    userkeys = @redis.keys('user:*:rho__id')
    userkeys.map{|u| @redis.get(u)}
  end
end