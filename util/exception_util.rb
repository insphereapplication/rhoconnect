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
    InsiteLogger.error(:format_and_join => [
      "Exception! ",
      {
        :message => exception.message, 
        :class => exception.class, 
        :context => @context, 
        :given_string => exception_string, 
        :backtrace => exception.backtrace
      }
    ])
  end # print_exception
  
end # class