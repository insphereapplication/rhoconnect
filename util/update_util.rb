require 'ap'

class UpdateUtil
  def self.push_update(source, update_hash, reraise_lock_exception=false)
    push_hash = build_push_hash(update_hash)
    InsiteLogger.info(:format_and_join => ["*"*10 + "Committing update to redis for model #{source.name} for user #{source.user_id}: ", push_hash])
    rejected_creates = []
    
    using_source_sync(source,reraise_lock_exception) do |source_sync|
      rejected_creates = source_sync.push_object_updates(push_hash)
      InsiteLogger.info(:format_and_join => ["Objects ", rejected_creates, " do not exist in redis; updates to these objects were rejected for user #{source.user_id}."]) if rejected_creates.count > 0
    end
    
    rejected_creates
  end
  
  def self.push_createupdate(source, createupdate_hash, reraise_lock_exception=false)
    push_hash = build_push_hash(createupdate_hash)
    InsiteLogger.info(:format_and_join => ["*"*10 + "Committing create/update to redis for model #{source.name} for user #{source.user_id}: ", push_hash])
    using_source_sync(source,reraise_lock_exception) do |source_sync|
      source_sync.push_objects(push_hash)
    end
  end
  
  def self.push_objects(source, objects, reraise_lock_exception=false)
    InsiteLogger.info(:format_and_join => ["*"*10 + "Committing to redis for model #{source.name} for user #{source.user_id}: ", objects])
    using_source_sync(source,reraise_lock_exception) do |source_sync|
      source_sync.push_objects(objects)
    end
  end
  
  private
  
  def self.build_push_hash(object_hash)
    {object_hash['id'] => object_hash.reject{ |k,v| k == 'id'}}
  end
  
  def self.using_source_sync(source, reraise_lock_exception)
    begin      
      yield(SourceSync.new(source)) if block_given?
    rescue StoreLockException
      # reset sync status for user
      user_key_pattern = "username:#{source.user_id}:[^:]*:initialized"
      InsiteLogger.info "Got StoreLockException for user #{source.user_id} in update util; resetting sync status for pattern #{user_key_pattern}."
      Store.flash_data(user_key_pattern)
      reraise_lock_exception ? raise : InsiteLogger.info(:format_and_join => ["Not re-raising, call stack: ",caller])
    end
  end
end