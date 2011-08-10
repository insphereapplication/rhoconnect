class DeadLockCheck < HealthCheck
  def initialize
    super("Dead lock")
    @results = {}
    run
  end
  
  def run
    log_run
    log_and_continue do
      dead_locks = HealthCheckUtil.rhosync_api.get_dead_locks
      log "Got dead locks: #{InsiteLogger.format_for_logging(dead_locks)}"
      @result = dead_locks
    end
  end
  
  def passed
     (@result.count == 0)
  end
  
  def result_summary
    super + " #{@result.count} dead locks detected."
  end
  
  def result_details
    details = @result.sort{|x,y| x[0] <=> y[0]}.reduce([]){|sum,(lock_key,time)|
      sum << "Lock '#{lock_key}' expired at #{time.to_s}"
      sum
    }.join("\n")
    super + "\n#{details}"
  end
end