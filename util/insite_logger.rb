require 'socket'
require 'logger'

module InsiteLogger  
  
  # If input is a string, return the string; otherwise, format using awesome_print
  def self.format_for_logging(input)
    input.kind_of?(String) ? input.gsub(/[\n\r\t]/,"") : input.awesome_inspect(:multiline => false, :plain => true)
  end
  
  # Log at the given level
  # Set format_and_join_array=true when you want to print a one-liner with the formatted and joined form of the array given by message
  # i.e. 
  #   self.info(:format_and_join => ["Test beginning ",{:a => "a", :b => "B"}," test end."])
  # will print 
  #   Test beginning { :a => "a", :b => "B" } test end.
  def self.add(level, input, params={})
    if input.kind_of?(Hash) && input.count == 1 && input[:format_and_join].kind_of?(Array)
      # Format each element in the array and join
      input = (input[:format_and_join].map{|value| format_for_logging(value)}).join('')
    else
      # Format 
      input = format_for_logging(input)
    end
    
    message = "#{host_name}:#{release_dir} -- #{input}"
        
    stdout_logger.add(level, message) if log_to_stdout? and params[:no_stdout].nil?

    file_logger.add(level, message) if log_to_file? and file_logger
  end
  
  def self.info(input, params={})
    add(Logger::INFO, input, params)
  end
  
  def self.error(input, params={})
    add(Logger::ERROR, input, params)
  end
  
  def self.debug(input, params={})
    add(Logger::DEBUG, input, params)
  end
  
  def self.file_logger
    init_logger unless @file_logger
    @file_logger
  end
  
  def self.stdout_logger
    @stdout_logger ||= Logger.new(STDOUT)
    @stdout_logger
  end
  
  def self.init_logger(log_path = nil)    
    log_conf = CONFIG[:log]
    log_path ||= log_conf[:path] 
    log_level = log_conf[:level] ? Integer(log_conf[:level]) : 0
    
    if log_to_file? 
      Dir.mkdir(File.dirname(log_path)) unless File.exists?(File.dirname(log_path))
      # Create a new logger instance at the configured logging path
      # Don't automatically archive/shift logs; logrotate will handle this.
      # I think job are not doing this automatically so trying to set up rotate
      @file_logger = Logger.new(log_path, 30,  'daily')
      @file_logger.level = log_level
    end
  end
  
  def self.log_to_file?
    @log_to_file ||= ['file','both'].include?(CONFIG[:log][:mode]) 
    @log_to_file
  end
  
  def self.log_to_stdout?
    @log_to_stdout ||= ['stdout','both'].include?(CONFIG[:log][:mode])
    @log_to_stdout
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