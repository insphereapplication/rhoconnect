Rhosync::Server.api :push_mapped_objects do |params,user|
  ExceptionUtil.rescue_and_reraise do
    InsiteLogger.info "#"*80
    InsiteLogger.info "PUSH MAPPED #{params[:source_id]} OBJECTS FOR #{params[:user_id]}"
      
    source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})

    InsiteLogger.info "SOURCE:"
    InsiteLogger.info source
    source_sync = SourceSync.new(source)
      
    objects = Mapper.map_source_data(params[:objects], params[:source_id])
      
    InsiteLogger.info "PARSED OBJECTS:"
    InsiteLogger.info objects
      
    source_sync.push_objects(objects)
  end
end