Rhosync::Server.api :get_dead_locks do |params,user|
  ExceptionUtil.rescue_and_reraise do
    lock_keys = Store.db.keys("lock:*")
    
    locks = lock_keys.reduce({}){|sum,key| sum[key] = Store.db.get(key); sum}
    
    min_valid_lock_timeout = Time.now.to_i - (CONFIG[:lock_duration] || 1)
    
    dead_locks = locks.reject{|key,value| value.nil? || value.to_i > min_valid_lock_timeout }
    
    InsiteLogger.info(:format_and_join => ["Get dead locks checked ",locks," for timeouts before #{min_valid_lock_timeout} and returned ",dead_locks])
    
    dead_locks.to_json
  end
end