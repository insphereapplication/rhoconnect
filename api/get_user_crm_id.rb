Rhoconnect::Server.api :get_user_crm_id do |params,user|
  ExceptionUtil.rescue_and_reraise do
    username = params[:username]
    crm_id = UserUtil.get_crm_id(username)
    InsiteLogger.info("Got CRM user ID from rhoconnectfor #{username}: #{crm_id}")
    crm_id
  end
end