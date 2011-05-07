class ClientException < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
  end
 
  def query(params=nil)
  end
 
  def sync
  end
 
  def create(client_exception,blob=nil)
    ExceptionUtil.rescue_and_reraise do
      puts "CREATE EXCEPTION"
      ap client_exception
      e = Exception.new(client_exception['message'])
      ExceptionUtil.context(:client_exception_data => e.inspect)
      ExceptionUtil.handle(e, "Client raised error: #{client_exception['backtrace']}")

      client_exception['exception_id']
    end
  end
 
  def update(update_hash)
  end
 
  def delete(object_id)
  end
 
  def logoff
  end
end