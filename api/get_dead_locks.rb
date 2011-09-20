Rhosync::Server.api :get_dead_locks do |params,user|
  ExceptionUtil.rescue_and_reraise do    
    dead_locks = LockUtil.get_dead_locks
    
    InsiteLogger.info(:format_and_join => ["Get dead locks checked for locks older than #{LockUtil.lock_age_threshold} seconds and returned ",dead_locks])
    
    dead_locks.to_json
  end
end