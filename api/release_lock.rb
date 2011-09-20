Rhosync::Server.api :release_lock do |params,user|
  ExceptionUtil.rescue_and_reraise do
    lock = params[:lock]
    InsiteLogger.info("Releasing lock '#{lock}'")
    
    if LockUtil.release_lock(lock)
      result = "Successfully released lock '#{lock}'"
      InsiteLogger.info(result)
      result
    else
      raise "Lock '#{lock}' doesn't exist"
    end
  end
end