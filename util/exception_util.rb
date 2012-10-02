class ExceptionUtil
  def self.rescue_and_reraise(&block)
    resque_and_log(false, &block)
  end
  
  def self.rescue_and_continue(&block)
    resque_and_log(true, &block)
  end
  
  def self.resque_and_log(continue=false, &block)
    begin
      yield if block_given?
    rescue Exception => e
      print_exception(e)
      raise e unless continue
    ensure
      @context = []
    end
  end
  
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
        :inspect => exception.inspect,
        :class => exception.class, 
        :context => @context, 
        :given_string => exception_string, 
        :backtrace => exception.backtrace
      }
    ])
  end # print_exception
  
end # class