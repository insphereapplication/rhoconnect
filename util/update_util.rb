require 'ap'

class UpdateUtil
  def self.push_objects(source, object_hash, reraise_lock_exception=false)
    begin
      redis_hash = {object_hash['id'] => object_hash.reject{ |k,v| k == 'id'}}
      InsiteLogger.info(:format_and_join => ["*"*10 + "Committing to redis for user #{source.user_id}: ", redis_hash])
    
      source_sync = SourceSync.new(source)
      source_sync.push_objects(redis_hash, CONFIG[:redis_lock_timeout], true)
    rescue StoreLockException
      # reset sync status for user
      user_key_pattern = "username:#{source.user_id}:[^:]*:initialized"
      InsiteLogger.info "Got StoreLockException for user #{source.user_id} in update util; resetting sync status for pattern #{user_key_pattern}."
      Store.flash_data(user_key_pattern)
      reraise_lock_exception ? raise : InsiteLogger.info(:format_and_join => ["Not re-raising, call stack: ",caller])
    end
  end
end