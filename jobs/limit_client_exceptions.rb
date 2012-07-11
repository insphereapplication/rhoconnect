root_path = File.expand_path("#{File.dirname(__FILE__)}/..")
require "#{root_path}/jobs/rhoconnect_resque_job"

class LimitClientExceptions 
  CLIENT_EXCEPTION_LIMIT = 100
  @queue = :limit_client_exceptions
  
  include RhoconnectResqueJob
    
  class << self
    def perform
      InsiteLogger.info "Initiating resque job LimitClientExceptions..."
      ExceptionUtil.rescue_and_continue do
        users.each do |user| 
          client_exceptions = rhoconnect_api.get_db_doc("source:application:#{user}:ClientException:md")
          InsiteLogger.info "Limiting client exceptions for user #{user}"
          # the key of each ClientException record in redis is based on the time the exception was thrown, 
          # so we can safely sort and remove exceptions based on the value of that
          client_exception_count = client_exceptions.count
          if client_exception_count > client_exception_limit
            # Keep the n most recent client exceptions, where n=client_exception_limit
            removed_exception_ids = client_exceptions.keys.sort.slice(0,client_exception_count-client_exception_limit)
            InsiteLogger.info(:format_and_join => ["Removing #{removed_exception_ids.count} exceptions for user #{user}: ",removed_exception_ids])
            rhoconnect_api.push_deletes('ClientException',user,removed_exception_ids)
          else
            InsiteLogger.info "No exceptions to remove for user #{user}"
          end
        end
      end
    end
    
    
    def client_exception_limit
      CLIENT_EXCEPTION_LIMIT
    end
  end
end