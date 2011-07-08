class SyncStatusUtil
  class << self
    def reset_sync_status(user_pattern)
      InsiteLogger.info "RESET SYNC STATUS FOR USERS MATCHING PATTERN #{user_pattern}"

      init_key_pattern = "username:#{user_pattern}:[^:]*:initialized"
      refresh_time_key_pattern = "read_state:application:#{user_pattern}:[^:]*:refresh_time"

      init_keys = Store.db.keys(init_key_pattern)
      refresh_time_keys = Store.db.keys(refresh_time_key_pattern)

      # Flash init keys  
      InsiteLogger.info(:format_and_join => ["Deleting init keys: ",init_keys])  
      init_keys.each do |key|
        Store.db.del(key)
      end

      # Set refresh time keys to now
      new_refresh_time = Time.now.to_i.to_s
      InsiteLogger.info(:format_and_join => ["Resetting refresh time to #{new_refresh_time} for keys: ",refresh_time_keys])
      refresh_time_keys.each do |key|
        Store.db.set(key,new_refresh_time)
      end

      refresh_time_values = refresh_time_keys.reduce({}){|sum,key|
        sum[key] = new_refresh_time
        sum
      }

      {:matching_init_keys => init_keys, :matching_refresh_time_keys => refresh_time_values}
    end
  end
end