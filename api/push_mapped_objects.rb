Rhosync::Server.api :push_mapped_objects do |params,user|
  ExceptionUtil.rescue_and_reraise do
    InsiteLogger.info "#"*80
    InsiteLogger.info "PUSH OBJECTS #{params[:source_id]} OBJECTS FOR #{params[:user_id]}"
    
    source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})

    InsiteLogger.info "SOURCE:"
    InsiteLogger.info source
    InsiteLogger.info "SOURCE USER: #{source.user.inspect}"
    
    objects = Mapper.map_source_data(params[:objects], params[:source_id])
  
    UpdateUtil.push_objects(source, objects, true)
    ""
  end
end