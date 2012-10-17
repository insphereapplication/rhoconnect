root_path = File.expand_path("#{File.dirname(__FILE__)}/..")
require "#{root_path}/initializers/object_extension"
require "#{root_path}/util/insite_logger"
require "#{root_path}/util/exception_util"
require "#{root_path}/util/config_file"
require "#{root_path}/util/rhoconnect_api_session"
require "#{root_path}/util/email_util"

module RhoconnectResqueJob
  module ClassMethods  
    @@rhoconnect_api = nil
  
    def rhoconnect_api
      @@rhoconnect_api ||= RhoconnectApiSession.new(CONFIG[:resque_worker_rhoconnect_api_host], CONFIG[:resque_worker_rhoconnect_api_password])
    end
  
    def users
      rhoconnect_api.get_all_users
    end
  end
  
  def rhoconnect_api
    #call corresponding class method
    self.class.rhoconnect_api
  end
  
  def users
    #call corresponding class method
    self.class.users
  end

  def self.included(model)
    model.extend(ClassMethods)
  end
end
