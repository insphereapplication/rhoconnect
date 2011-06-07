require 'socket'

module InsiteLogger  

  def self.info(message)
    output_host_name
    ap message  
    message = message.kind_of?(Array) ? message.join("\n") : message.inspect
    insite_logger.info("#{host_name}:#{release_dir} -- #{message}") if insite_logger
  end
  
  def self.insite_logger
    init_logger unless @logger
    @logger
  end
  
  def self.init_logger
    log_conf = CONFIG[:log]
    
    if log_conf[:mode] == 'file' 
      Dir.mkdir(File.dirname(log_conf[:path])) unless File.exists?(File.dirname(log_conf[:path]))
      log = File.new(log_conf[:path], "a")      
      @logger = Logger.new(log) 
    end
  end
  
  def self.output_host_name
    print "#{host_name}:#{release_dir} -- "
  end
  
  def self.host_name
    @host_name ||= `echo $HOSTNAME`.strip
  rescue
    "hostname unavailable"
  end
  
  def self.release_dir
    @release_dir ||= lambda {
      release_dir = File.expand_path(File.dirname(__FILE__) + '/..')
      release_dir.match(/[^\/]*?$/).to_s
    }.call
  rescue
    "release_dir unavailable"
  end
end