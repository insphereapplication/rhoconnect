class TimerUtil
  def self.time_block
    start_time = Time.now
    yield
    Time.now - start_time
  end
end