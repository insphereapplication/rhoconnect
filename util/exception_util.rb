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
  
  def self.print_exception(exception, exception_string=nil)
    InsiteLogger.info "*** EXCEPTION TYPE ***"
    InsiteLogger.info exception.inspect
    InsiteLogger.info "*** EXCEPTION CONTEXT ***"
    InsiteLogger.info "#{@context.inspect}"
    InsiteLogger.info "*** EXCEPTION STRING ***"
    InsiteLogger.info exception_string
    InsiteLogger.info "*** EXCEPTION STACK TRACE ***"
    InsiteLogger.info caller.join("\n")
    InsiteLogger.info "*** END EXCEPTION ***"
  end # print_exception
  
end # class