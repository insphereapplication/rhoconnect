Rhosync::Server.api :get_user_token do |params,user|
  ExceptionUtil.rescue_and_reraise do
    Store.get_value("username:#{params[:username].downcase}:token")
  end
end