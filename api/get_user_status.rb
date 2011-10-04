Rhosync::Server.api :get_user_status do |params,user|
  ExceptionUtil.rescue_and_reraise do
    user_id = params[:user_id]
    disabled_at = UserUtil.disabled_at(user_id)
    status = disabled_at ? 'disabled' : 'enabled'
    {:status => status, :time => disabled_at}.to_json
  end
end