require File.expand_path("#{File.dirname(__FILE__)}/rhosync_resque_job")
require 'time'
require 'set'

class ReleaseDeadLocks
  @queue = :release_dead_locks
  
  include RhosyncResqueJob
    
  class << self
    def perform
      set_log_file_name(@queue.to_s)
      
      environment = CONFIG[:env]
      start_time = Time.now
      
      log "Initiating resque job ReleaseDeadLocks..."
      ExceptionUtil.rescue_and_reraise do
        dead_locks = rhosync_api.get_dead_locks
        log ["Found dead locks: ", dead_locks]
        
        users_to_reset = Set.new
        
        dead_locks.each do |lock,expiration|
          log_and_continue do
            log "Releasing lock #{lock}"
            rhosync_api.release_lock(lock)
            
            user_match = lock.match(/^lock:[^:]+:[^:]+:([^:]+):/)
            users_to_reset.add(user_match[1]) if user_match
          end
        end
        
        users_to_reset = users_to_reset.to_a
        
        log "Done releasing dead locks, resetting sync status for users #{users_to_reset.join(', ')}"
        
        users_to_reset.each do |user|
          log_and_continue do
            log "Resetting sync status for user #{user}"
            rhosync_api.reset_sync_status(user)
          end
        end
        
        if dead_locks.count > 0
          # send summary e-mail
          file_path = File.expand_path("#{File.dirname(__FILE__)}/templates/release_dead_locks_email.erb")
          email_template = ERB.new( File.read(file_path), nil, '<>')
          email_body = email_template.result(binding)
          to = CONFIG[:resque_data_validation_email_group]
          subject = "RhoSync - #{dead_locks.count} dead lock(s) detected!"
          EmailUtil.send_mail(to, subject, email_body)
        end
        
        log "ReleaseDeadLocks resque job complete"
      end
    end
  end
end
