Rhosync::Server.api :reset_sync_status do |params,user|
  ExceptionUtil.rescue_and_reraise do
    user_pattern = params[:user_pattern]
    InsiteLogger.info "RESET SYNC FOR USERS MATCHING PATTERN #{user_pattern}"
    InsiteLogger.info params
  
    init_key_pattern = "username:#{user_pattern}:[^:]*:initialized"
  
    user_keys = Store.get_keys(init_key_pattern)
  
    InsiteLogger.info "Found keys:"
    InsiteLogger.info user_keys
  
    flash_result = Store.flash_data(init_key_pattern)
    InsiteLogger.info "Flash result:"
    InsiteLogger.info flash_result
  
    flash_result.to_json
  end
end