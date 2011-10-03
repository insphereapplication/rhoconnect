root_path = File.expand_path("#{File.dirname(__FILE__)}/..")
require "#{root_path}/initializers/object_extension"
require "#{root_path}/util/insite_logger"
require "#{root_path}/util/exception_util"
require "#{root_path}/util/config_file"
require "#{root_path}/util/rhosync_api_session"
require "#{root_path}/util/email_util"

module RhosyncResqueJob
  module ClassMethods  
    @@rhosync_api = nil
  
    def rhosync_api
      @@rhosync_api ||= RhosyncApiSession.new(CONFIG[:resque_worker_rhosync_api_host], CONFIG[:resque_worker_rhosync_api_password])
    end
  
    def users
      rhosync_api.get_all_users
    end
  end
  
  def rhosync_api
    #call corresponding class method
    self.class.rhosync_api
  end
  
  def users
    #call corresponding class method
    self.class.users
  end

  def self.included(model)
    model.extend(ClassMethods)
  end
end
