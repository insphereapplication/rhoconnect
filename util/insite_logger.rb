require 'logger'

module InsiteLogger  

  def self.info(message)
    message = message.to_s
    InsiteLogger.insite_logger.info(message)
  end
  
  def self.error(message)
    insite_logger.error(message)
  end
  
  def self.add(message)
    insite_logger.add(message) 
  end
  
  def self.insite_logger
    init_logger unless @logger
    @logger
  end
  
  def self.init_logger
    conf = CONFIG[:log]
    Dir.mkdir(File.dirname(conf[:path])) unless File.exists?(File.dirname(conf[:path]))
    @logger = Logger.new(conf[:path], conf[:num_old_logs], conf[:max_log_size]) 
  end
end