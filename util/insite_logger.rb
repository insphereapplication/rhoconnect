require 'socket'

module InsiteLogger  
  
  # If input is a string, return the string; otherwise, format using awesome_print
  def self.format_for_logging(input)
    input.kind_of?(String) ? input : input.awesome_inspect(:multiline => false, :plain => true)
  end
  
  # Log at the given level
  # Set format_and_join_array=true when you want to print a one-liner with the formatted and joined form of the array given by message
  # i.e. 
  #   self.info(:format_and_join => ["Test beginning ",{:a => "a", :b => "B"}," test end."])
  # will print 
  #   Test beginning { :a => "a", :b => "B" } test end.
  def self.add(level, input)
    if input.kind_of?(Hash) && input.count == 1 && input[:format_and_join].kind_of?(Array)
      # Format each element in the array and join
      input = (input[:format_and_join].map{|value| format_for_logging(value)}).join('')
    else
      # Format 
      input = format_for_logging(input)
    end
    output_host_name
    puts input
    insite_logger.add(level, "#{host_name}:#{release_dir} -- #{input}") if insite_logger
  end
  
  def self.info(input)
    add(Logger::INFO, input)
  end
  
  def self.error(input)
    add(Logger::ERROR, input)
  end
  
  def self.insite_logger
    init_logger unless @logger
    @logger
  end
  
  def self.init_logger
    log_conf = CONFIG[:log]
    
    if log_conf[:mode] == 'file' 
      Dir.mkdir(File.dirname(log_conf[:path])) unless File.exists?(File.dirname(log_conf[:path]))
      # Create a new logger instance at the configured logging path
      # Don't automatically archive/shift logs; logrotate will handle this.
      @logger = Logger.new(log_conf[:path], 0)
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