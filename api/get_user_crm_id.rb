Rhosync::Server.api :get_user_crm_id do |params,user|
  ExceptionUtil.rescue_and_reraise do
    username = params[:username]
    InsiteLogger.info("Getting the crm_user_id from rhosync for #{username}")
    key = "username:#{username}:crm_user_id"
    crm_id = Store.get_value("#{key}")
    InsiteLogger.info("key: #{key},  crm_id #{crm_id}")
    crm_id
  end
end