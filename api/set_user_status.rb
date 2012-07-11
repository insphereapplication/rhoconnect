Rhoconnect::Server.api :set_user_status do |params,user|
  ExceptionUtil.rescue_and_reraise do
    user_id = params[:user_id]
    status = params[:status]
    InsiteLogger.info("Setting user status to #{status} for user #{user_id}")
    case status
    when 'enabled'
      UserUtil.enable_if_disabled(user_id)
    when 'disabled'
      UserUtil.disable_if_enabled(user_id)
    else
      raise "Status must either be 'enabled' or 'disabled'"
    end
    'done'
  end
end