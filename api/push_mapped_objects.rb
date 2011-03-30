Rhosync::Server.api :push_mapped_objects do |params,user|
  # ap "PUSH MAPPED #{params[:source_id]} OBJECTS FOR #{user}"
  #   ap params
  
  source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
  source_sync = SourceSync.new(source)
  
  objects = Mapper.map_source_data(params[:objects], params[:source_id])
  
  # ap "PARSED OBJECTS:"
  #   ap objects
  
  source_sync.push_objects(objects)

end