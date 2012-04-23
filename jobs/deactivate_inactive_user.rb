require File.expand_path("#{File.dirname(__FILE__)}/../jobs/rhosync_resque_job")
require 'time'

class DeactivateInactiveUser
  MAX_DEVICE_INACTIVE_DAYS = 30
  MAX_USER_INACTIVE_DAYS = 14
  SECONDS_IN_A_DAY = 86400
  @queue = :deactivate_inactive_user

  include RhosyncResqueJob
    
  class << self
    def perform
      InsiteLogger.info "Initiating resque job decactivate inactive users"
      ExceptionUtil.rescue_and_continue do
        
        users.each do |user|
          #If none of the user devices are active
          device_infos =  rhosync_api.get_db_doc("source:application:#{user}:DeviceInfo:md")
          devices = rhosync_api.get_user_devices(user)
          InsiteLogger.info("*"*10 + " Checking to see if #{user} is active")
          if device_infos.nil? || device_infos.count <=0 || is_inactive_user(device_infos)
            InsiteLogger.info("#{user} is inactive")
            disable_user(user)
            reset_sync_status(user)    
          else 
            InsiteLogger.info("#{user} is active")
          end

          # checking device for inactivity
          InsiteLogger.info("Checking for old devices for user: #{user}")
          old_devices = get_expired_devices(devices,device_infos)
          if old_devices.nil? || old_devices.count == 0
            InsiteLogger.info(:format_and_join => ["There are no old devices for #{user}"])
          else
            InsiteLogger.info(:format_and_join => ["Deleting the following device infos for #{user} that have not sync in #{MAX_DEVICE_INACTIVE_DAYS} days:",old_devices])
            rhosync_api.push_deletes('DeviceInfo',user,old_devices) unless old_devices.empty?
            InsiteLogger.info(:format_and_join => ["Deleting the following devices for #{user} that have not sync in #{MAX_DEVICE_INACTIVE_DAYS} days:",old_devices])
            old_devices.each {|old_device_id| rhosync_api.delete_device(user,old_device_id)} unless old_devices.empty?
          end
  
          current_devices = rhosync_api.get_user_devices(user)
          if (current_devices.nil? || current_devices.count <=0)
            InsiteLogger.info(:format_and_join => ["Deleting #{user} since there are no current devices"])
            rhosync_api.delete_user(user)
          end  
        end
      end
    end
    
    def is_inactive_user(device_infos)
     
      last_sync_device = device_infos.max_by {|id,device_info| 
         if device_info['last_sync'] 
           Time.parse(device_info['last_sync']).to_i
         else
           0
         end
           }[1]

        begin
          InsiteLogger.info( "Is #{last_sync_device['client_id']} last sync time inactive: #{Time.parse(last_sync_device['last_sync']).to_i < Time.now.to_i - SECONDS_IN_A_DAY*MAX_DEVICE_INACTIVE_DAYS}")
          Time.parse(last_sync_device['last_sync']).to_i < Time.now.to_i - SECONDS_IN_A_DAY*MAX_USER_INACTIVE_DAYS
        rescue Exception => e
           ExceptionUtil.print_exception(e)
           # If time parsing or other logic fails, assume inactive
           InsiteLogger.info( "Is #{last_sync_device['client_id']} device inactive: True")
           true
        end      
 
    end
    
    def reset_sync_status(user)
      begin
        rhosync_api.reset_sync_status("#{user}")
      rescue Exception => e
        ExceptionUtil.print_exception(e)
        InsiteLogger.error("Error reset the sync status for #{user}")
      end
    end
    
    def disable_user(user)
      begin
        rhosync_api.set_user_status(user,'disabled')
      rescue Exception => e
        ExceptionUtil.print_exception(e)
        InsiteLogger.error("Error setting the mobile flag to false for:  #{user}")
      end
    end  
    
    
    def get_expired_devices(devices,device_infos)
      devices.select do |key, device|
        begin  
           device_info = device_infos.find{|id,info| info["client_id"] == key} 
           InsiteLogger.info("Checking device: #{key} is expired: #{device_info.nil?  || device_info[1]['last_sync'].nil? || Time.parse(device_info[1]['last_sync']).to_i < Time.now.to_i - SECONDS_IN_A_DAY*MAX_DEVICE_INACTIVE_DAYS}")
           device_info.nil? || device_info[1]['last_sync'].nil? || Time.parse(device_info[1]['last_sync']).to_i < Time.now.to_i - SECONDS_IN_A_DAY*MAX_DEVICE_INACTIVE_DAYS
        rescue Exception => e
           ExceptionUtil.print_exception(e)
          # If time parsing or other logic fails, assume expired
           InsiteLogger.info( "Is #{device} device #{key} expired: True")
          true
        end

      end
    end
    
    def get_doc_ids(doc)
      doc.map{|item| item[0]}
    end
    
  end    
    
end