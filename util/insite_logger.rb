module InsiteLogger  

  def self.info(message)
    ap message  
    message = message.kind_of?(Array) ? message.join("\n") : message.inspect
    insite_logger.info(message) if insite_logger
  end
  
  def self.insite_logger
    init_logger unless @logger
    @logger
  end
  
  def self.init_logger
    log_conf = CONFIG[:log]
    
    if log_conf[:mode] == 'file' 
      Dir.mkdir(File.dirname(log_conf[:path])) unless File.exists?(File.dirname(log_conf[:path]))
      @logger = Logger.new(log_conf[:path], log_conf[:num_old_logs], log_conf[:max_log_size]) 
    end
  end
end