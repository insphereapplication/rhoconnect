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
    ap "*** EXCEPTION TYPE ***"
    ap exception.inspect
    ap "*** EXCEPTION CONTEXT ***"
    ap "#{@context.inspect}"
    ap "*** EXCEPTION STRING ***"
    ap exception_string
    ap "*** EXCEPTION STACK TRACE ***"
    ap caller
    ap "*** END EXCEPTION ***"
  end # print_exception
  
end # class