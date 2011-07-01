root_path = File.expand_path("#{File.dirname(__FILE__)}/..")
require "#{root_path}/util/insite_logger"
require "#{root_path}/util/exception_util"
require "#{root_path}/util/config_file"
require 'rhosync'

module RhosyncResqueJob      
  # Override default rhosync store connection (localhost) with configured redis host
  Rhosync::Store.db.client.disconnect if defined?(Rhosync::Store.db.client)
  puts "Connecting to redis at #{CONFIG[:redis_url]}:#{CONFIG[:redis_port]}"
  Rhosync::Store.db = Redis.new(:thread_safe => true, :host => CONFIG[:redis_url], :port => CONFIG[:redis_port])
  
  def users
    userkeys = Rhosync::Store.db.keys('user:*:rho__id')
    userkeys.map{|u| Rhosync::Store.db.get(u)}
  end
end