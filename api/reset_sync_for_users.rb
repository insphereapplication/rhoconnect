Rhosync::Server.api :reset_sync_status do |params,user|
  Exceptional.rescue do
    user_pattern = params[:user_pattern]
    ap "RESET SYNC FOR USERS MATCHING PATTERN #{user_pattern}"
    ap params
  
    init_key_pattern = "username:#{user_pattern}:[^:]*:initialized"
  
    user_keys = Store.get_keys(init_key_pattern)
  
    ap "Found keys:"
    ap user_keys
  
    flash_result = Store.flash_data(init_key_pattern)
    ap "Flash result:"
    ap flash_result
  
    flash_result.to_json
  end
end