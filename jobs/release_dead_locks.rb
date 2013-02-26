require File.expand_path("#{File.dirname(__FILE__)}/rhoconnect_resque_job")
require 'time'
require 'set'

class ReleaseDeadLocks
  @queue = :release_dead_locks
  
  include RhoconnectResqueJob
    
  class << self
    def perform
      environment = CONFIG[:env]
      start_time = Time.now
      
      InsiteLogger.info("Initiating resque job ReleaseDeadLocks...")
      ExceptionUtil.rescue_and_continue do
        dead_locks = rhoconnect_api.get_dead_locks
        InsiteLogger.info(:format_and_join => ["Found dead locks: ", dead_locks])
        
        users_to_reset = Set.new
        
        dead_locks.each do |lock,expiration|
          ExceptionUtil.rescue_and_continue do
            InsiteLogger.info("Releasing lock #{lock}")
            rhoconnect_api.release_lock(lock)
            
            user_match = lock.match(/^lock:[^:]+:[^:]+:([^:]+):/)
            users_to_reset.add(user_match[1]) if user_match
          end
        end
        
        users_to_reset = users_to_reset.to_a
        
        InsiteLogger.info("Done releasing dead locks, resetting sync status for users #{users_to_reset.join(', ')}")
        
        users_to_reset.each do |user|
          ExceptionUtil.rescue_and_continue do
            InsiteLogger.info("Resetting sync status for user #{user}")
            rhoconnect_api.reset_sync_status(user)
          end
        end
        
        if dead_locks.count > 0
          # send summary e-mail
          file_path = File.expand_path("#{File.dirname(__FILE__)}/templates/release_dead_locks_email.erb")
          email_template = ERB.new( File.read(file_path), nil, '<>')
          email_body = email_template.result(binding)
          to = CONFIG[:resque_data_validation_email_group]
          subject = "RhoConnect - #{dead_locks.count} dead lock(s) detected!"
          EmailUtil.send_mail(to, subject, email_body)
        end
        
        InsiteLogger.info("ReleaseDeadLocks resque job complete")
      end
    end
  end
end
