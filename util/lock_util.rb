class LockUtil
  class << self
    def lock_age_threshold
      ((CONFIG[:lock_duration] || 1) * 2)
    end
    
    def get_dead_locks
      lock_keys = Store.db.keys("lock:*")

      locks = lock_keys.reduce({}){|sum,key| sum[key] = Store.db.get(key); sum}

      min_valid_lock_timeout = Time.now.to_i - lock_age_threshold

      locks.reject{|key,value| value.nil? || value.to_i > min_valid_lock_timeout }
    end
    
    def release_lock(lock_key)
      # TODO: check if lock is actually dead first?
      raise "Given key #{lock_key} is not a lock" unless lock_key[/^lock:/]
      Store.db.del(lock_key)
    end
  end
end