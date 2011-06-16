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
      InsiteLogger.info(:format_and_join => ["!!! Client exception created: ",client_exception])

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