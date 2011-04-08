Rhosync::Server.api :get_user_token do |params,user|
  Exceptional.rescue_and_reraise do
    Store.get_value("username:#{params[:username].downcase}:token")
  end
end