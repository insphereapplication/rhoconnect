root_path = File.expand_path("#{File.dirname(__FILE__)}/..")
require "#{root_path}/initializers/object_extension"
require "#{root_path}/util/insite_logger"
require "#{root_path}/util/exception_util"
require "#{root_path}/util/config_file"
require "#{root_path}/util/rhosync_api_session"

module RhosyncResqueJob
  
  @@rhosync_api = nil
  
  def rhosync_api
    @@rhosync_api ||= RhosyncApiSession.new(CONFIG[:resque_worker_rhosync_api_host], CONFIG[:resque_worker_rhosync_api_password])
  end
  
  def users
    rhosync_api.get_all_users
  end
end