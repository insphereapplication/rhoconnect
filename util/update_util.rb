require 'ap'

class UpdateUtil
  def self.push_objects(source, object_hash, reraise_lock_exception=false)
    begin
      redis_hash = {object_hash['id'] => object_hash.reject{ |k,v| k == 'id'}}
      InsiteLogger.info "*"*80
      InsiteLogger.info "Committing to redis for user #{source.user_id}:"
      InsiteLogger.info redis_hash
    
      source_sync = SourceSync.new(source)
      source_sync.push_objects(redis_hash, CONFIG[:redis_lock_timeout], true)
    rescue StoreLockException
      # reset sync status for user
      InsiteLogger.info "Got StoreLockException for user #{source.user_id} in update util; resetting sync status."
      user_key_pattern = "username:#{source.user_id}:[^:]*:initialized"
      Store.flash_data(user_key_pattern)
      InsiteLogger.info "Reset sync status for keys matching pattern #{user_key_pattern}"
      raise if reraise_lock_exception
    end
  end
end