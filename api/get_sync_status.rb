Rhoconnect::Server.api :get_sync_status do |params,user|
  ExceptionUtil.rescue_and_reraise do
    user_pattern = params[:user_pattern]
    init_key_pattern = "username:#{user_pattern}:[^:]*:initialized"
    refresh_time_key_pattern = "read_state:application:#{user_pattern}:[^:]*:refresh_time"
    init_keys = Store.db.keys(init_key_pattern)
    refresh_time_keys = Store.db.keys(refresh_time_key_pattern)
    
    refresh_time_values = {}
    
    refresh_time_keys.each do |key|
      refresh_time_values[key] = Store.db.get(key)
    end
    
    {:matching_init_keys => init_keys, :matching_refresh_time_keys => refresh_time_values}.to_json
  end
end