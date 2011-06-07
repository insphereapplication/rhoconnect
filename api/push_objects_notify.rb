Rhosync::Server.api :push_objects_notify do |params,user|
  ExceptionUtil.rescue_and_reraise do
    begin
      InsiteLogger.info "#"*80
      InsiteLogger.info "PUSH OBJECTS NOTIFY #{params[:source_id]} OBJECTS FOR #{params[:user_id]}"

      source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
      InsiteLogger.info "SOURCE: #{source.inspect}"
      InsiteLogger.info "SOURCE USER: #{source.user.inspect}"

      objects = Mapper.map_source_data(params[:objects], params[:source_id])
      UpdateUtil.push_objects(source, objects, true)
    ensure
      # Ensure that the user gets a push notification even if push_objects fails
      InsiteLogger.info "push_objects_notify called, notifying observer for #{params[:source_id]}"
      klass = Object.const_get(params[:source_id].capitalize)
      klass.notify_api_pushed(params[:user_id]) if klass.respond_to?(:notify_api_pushed)
    end
    ""
  end
end