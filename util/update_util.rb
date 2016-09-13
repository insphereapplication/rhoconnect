require 'ap'

class UpdateUtil
  def self.push_update(source, update_hash, reraise_lock_exception=false)
    push_hash = build_push_hash(update_hash)
    PushHandler.handle_push(source.name, source.user_id, push_hash)
    InsiteLogger.info(:format_and_join => ["*"*10 + "Committing update to redis for model #{source.name} for user #{source.user_id}: ", push_hash])
    rejected_creates = []
	
    params = {:objects=>push_hash, :rebuild_md=>false, :timeout=>10}}
    using_source_sync(source,reraise_lock_exception) do |source_sync|
      #rejected_creates = source_sync.push_objects(push_hash,nil,nil,false)
	  rejected_creates = source_sync.push_objects(params)
    end
    
    rejected_creates
  end
  
  def self.push_createupdate(source, createupdate_hash, reraise_lock_exception=false)
    push_hash = build_push_hash(createupdate_hash)
    PushHandler.handle_push(source.name, source.user_id, push_hash)
    InsiteLogger.info(:format_and_join => ["*"*10 + "Committing create/update to redis for model #{source.name} for user #{source.user_id}: ", push_hash])
	  params = {:objects=>push_hash, :rebuild_md=>false, :timeout=>10}
	  using_source_sync(source,reraise_lock_exception) do |source_sync|
      #source_sync.push_objects(push_hash,nil,nil,false)
	    source_sync.push_objects(params)
    end
  end
  
  def self.push_objects(source, objects, reraise_lock_exception=false)
    PushHandler.handle_push(source.name, source.user_id, objects)
    InsiteLogger.info(:format_and_join => ["*"*10 + "Committing to redis for model #{source.name} for user #{source.user_id}: ", objects])
    params = {:objects=>objects, :rebuild_md=>false, :timeout=>10}}
	using_source_sync(source,reraise_lock_exception) do |source_sync|
      #source_sync.push_objects(objects,nil,nil,false)
	  source_sync.push_objects(params)
    end
  end
  
  private
  
  def self.build_push_hash(object_hash)
    {object_hash['id'] => object_hash.reject{ |k,v| k == 'id'}}
  end
  
  def self.using_source_sync(source, reraise_lock_exception)
    begin      
      yield(Rhoconnect::Model::Base.create(source)) if block_given?
    rescue StoreLockException
      # reset sync status for user
      InsiteLogger.info "Got StoreLockException for user #{source.user_id} in update util; resetting sync status."
      SyncStatusUtil.reset_sync_status(source.user_id)
      reraise_lock_exception ? raise : InsiteLogger.info(:format_and_join => ["Not re-raising, call stack: ",caller])
    end
  end
end