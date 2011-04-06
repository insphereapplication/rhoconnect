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
 
  def create(exception,blob=nil)
    Exceptional.rescue do
      puts "CREATE EXCEPTION"
      ap exception
      e = Exception.new(exception['message'])
      Exceptional.handle(e, "Client raised error: #{exception['backtrace']}")

      exception['exception_id']
    end
  end
 
  def update(update_hash)
  end
 
  def delete(object_id)
  end
 
  def logoff
  end
end