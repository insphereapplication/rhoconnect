Rhosync::Server.api :push_mapped_objects do |params,user|
  ExceptionUtil.rescue_and_reraise do
    InsiteLogger.info "PUSH MAPPED #{params[:source_id]} OBJECTS FOR #{user.inspect}"
    InsiteLogger.info params
  
    source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
    InsiteLogger.info "SOURCE:"
    InsiteLogger.info source
    source.name = source.id
    source_sync = SourceSync.new(source)
  
    objects = Mapper.map_source_data(params[:objects], params[:source_id])
  
    InsiteLogger.info "PARSED OBJECTS:"
    InsiteLogger.info objects
  
    source_sync.push_objects(objects)
  end
end