Rhoconnect::Server.api :force_query do |params,user|
  ExceptionUtil.rescue_and_reraise do
    user_id = params[:user_id]
    source_id = params[:source_id]
    
    InsiteLogger.info "Forcing query for source #{source_id} for user #{user_id}"
    
    #First, reset the user's sync status to ensure do_query will actually do something below
    SyncStatusUtil.reset_sync_status(user_id)
    
    #Get an instance of the source adapter
    credential = {:app_id=>APP_NAME,:user_id=>user_id}
    source = Source.load(source_id,credential)
    source_adapter = SourceAdapter.create(source,credential)
    
    #Follow the sync contract by first logging into the backend then calling do_query to refresh RhoSync's dataset
    source_adapter.login
    source_adapter.do_query
    
    InsiteLogger.info "Done forcing query for source #{source_id} for user #{user_id}"
  end
end