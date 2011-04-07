Rhosync::Server.api :get_sync_status do |params,user|
  Exceptional.rescue_and_reraise do
    user_pattern = params[:user_pattern]
    init_key_pattern = "username:#{user_pattern}:[^:]*:initialized"
    user_keys = Store.get_keys(init_key_pattern)
    user_keys.to_json
  end
end