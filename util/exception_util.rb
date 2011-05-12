class ExceptionUtil
  def self.rescue_and_reraise
    begin
      yield if block_given?
    rescue Exception => e
      print_exception(e)
      raise e
    ensure 
      @context = []
    end
  end # rescue_and_reraise
  
  def self.context(context)
    (@context ||= []) << context
  end # context
  
  def self.handle(exception, exception_string)
    print_exception(exception, exception_string)
  end # handle
  
  private
  
  def self.print_exception(exception, exception_string="")
   [ 
     "*** EXCEPTION MESSAGE ***",
     exception.message,
     "*** EXCEPTION TYPE ***",
     exception.class,
     "*** EXCEPTION CONTEXT ***",
     @context,
     "*** EXCEPTION STRING ***",
     exception_string,
     "*** EXCEPTION STACK TRACE ***",
     exception.backtrace,
     "*** END EXCEPTION ***"
    ].each { |line| InsiteLogger.info line }
  end # print_exception
  
end # class