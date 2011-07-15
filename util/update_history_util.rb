class UpdateHistoryUtil
  def initialize(source_name, user_id)
    @source_name = source_name
    @user_id = user_id
  end

  def touch(record_id, field_name)
    prior_update_time = last_update(record_id, field_name)
    new_update_time = Time.now
    Store.db.hset(tracked_updates_key, tracked_update_hash_key(record_id, field_name), new_update_time.to_i)
    {:prior_update_time => prior_update_time, :new_update_time => new_update_time}
  end

  def last_update(record_id, field_name)
    timestamp = Store.db.hget(tracked_updates_key, tracked_update_hash_key(record_id, field_name))
    timestamp.nil? ? nil : Time.at(timestamp.to_i)
  end

  def tracked_updates_key
    "update_history:#{@user_id}:#{@source_name}"
  end
  
  def tracked_update_hash_key(record_id, field_name)
    "#{record_id}:#{field_name}"
  end
end