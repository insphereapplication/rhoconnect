require 'ap'

class UpdateUtil
  def self.push_update(source, update_hash, reraise_lock_exception=false)
    redis_hash = {update_hash['id'] => update_hash.reject{ |k,v| k == 'id'}}
    push_objects(source,redis_hash,reraise_lock_exception)
  end
  
  def self.push_objects(source, objects, reraise_lock_exception=false)
    begin
      InsiteLogger.info(:format_and_join => ["*"*10 + "Committing to redis for user #{source.user_id}: ", objects])
    
      source_sync = SourceSync.new(source)
      source_sync.push_objects(objects)
    rescue StoreLockException
      # reset sync status for user
      user_key_pattern = "username:#{source.user_id}:[^:]*:initialized"
      InsiteLogger.info "Got StoreLockException for user #{source.user_id} in update util; resetting sync status for pattern #{user_key_pattern}."
      Store.flash_data(user_key_pattern)
      reraise_lock_exception ? raise : InsiteLogger.info(:format_and_join => ["Not re-raising, call stack: ",caller])
    end
  end
end