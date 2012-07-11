Rhoconnect::Server.api :reset_sync_status do |params,user|
  ExceptionUtil.rescue_and_reraise do
    SyncStatusUtil.reset_sync_status(params[:user_pattern]).to_json
  end
end