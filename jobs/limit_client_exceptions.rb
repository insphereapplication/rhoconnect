root_path = File.expand_path("#{File.dirname(__FILE__)}/..")
require "#{root_path}/jobs/rhosync_resque_job"

class LimitClientExceptions 
  include RhosyncResqueJob
  CLIENT_EXCEPTION_LIMIT = 100
  @queue = :limit_client_exceptions
  
  class << self
    def perform
      InsiteLogger.info "Initiating resque job LimitClientExceptions..."
      ExceptionUtil.rescue_and_reraise do
        get_master_docs.each do |user, client_exceptions|
          InsiteLogger.info "Limiting client exceptions for user #{user}"
          # the key of each ClientException record in redis is based on the time the exception was thrown, 
          # so we can safely sort and remove exceptions based on the value of that 
          keep_exceptions = client_exceptions.keys.sort.slice(0, client_exception_limit)
          if keep_exceptions && keep_exceptions.size > 0
            removed_exceptions = client_exceptions.reject{|k,v| keep_exceptions.include?(k) }
            Rhosync::Store.delete_data("source:application:#{user}:ClientException:md", removed_exceptions)
          end
          InsiteLogger.info "Client exceptions removed for user #{user}"
        end
      end
    end
    
    def get_master_docs
       users.map do |user| 
         [ 
           user,
           Rhosync::Store.get_data("source:application:#{user}:ClientException:md")
         ]
      end
    end
    
    def client_exception_limit
      CLIENT_EXCEPTION_LIMIT
    end
  end
end