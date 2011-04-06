class ClientException < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
        puts "LOGIN CLIENT EXCEPTION"
  end
 
  def query(params=nil)
    puts "QUERY CLIENT EXCEPTION"
  end
 
  def sync
        puts "SYNC CLIENT EXCEPTION"
  end
 
  def create(exception,blob=nil)
    puts "CREATE EXCEPTION"
    ap exception
    e = Exception.new(exception['message'])
    Exceptional.handle(e, "Client raised error: #{exception['backtrace']}")
    puts "DONE WITH EXCEPTIONAL"

    exception['exception_id']
  end
 
  def update(update_hash)
        puts "UPDATE CLIENT EXCEPTION"
  end
 
  def delete(object_id)
        puts "DELETE CLIENT EXCEPTION"
  end
 
  def logoff
     puts "LOGOFF CLIENT EXCEPTION"
  end
end