 Rhoconnect::Server.api :push_deletes_custom do |params,user|
  ExceptionUtil.rescue_and_reraise do
    deleted_objects = params[:objects]
    InsiteLogger.info(:format_and_join => ["PUSH DELETES #{params[:source_id]} FOR #{params[:user_id]}: ",deleted_objects])
    source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
    source_sync = SourceSync.new(source)
    source_sync.push_deletes(deleted_objects,nil,nil,false)
    'done'
  end
end