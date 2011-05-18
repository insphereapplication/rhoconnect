Rhosync::Server.api :push_objects_notify do |params,user|
  ExceptionUtil.rescue_and_reraise do
    InsiteLogger.info "PUSH OBJECTS NOTIFY #{params[:source_id]} OBJECTS FOR #{user.inspect}"
    InsiteLogger.info params

    source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
    InsiteLogger.info "SOURCE: #{source}"
    
    source_sync = SourceSync.new(source)

    objects = Mapper.map_source_data(params[:objects], params[:source_id])
    InsiteLogger.info "OBJECTS: #{objects}"
    source_sync.push_objects(objects)

    InsiteLogger.info "push_objects_notify called, notifying observer for #{params[:source_id]}"
    klass = Object.const_get(params[:source_id].capitalize)
    klass.notify_api_pushed(params[:user_id]) if klass.respond_to?(:notify_api_pushed)
  end
end