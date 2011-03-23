Rhosync::Server.api :push_objects_notify do |params,user|
  ap "PUSH OBJECTS NOTIFY FOR #{user}"
  ap params
  
  source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
  source_sync = SourceSync.new(source)
  objects = {}
  if params[:source_id] == 'Activity'
    ap "PROCESSING ACTIVITIES..."
    objects = ActivityMapper.map_json(params[:objects])
    ap objects
  elsif params[:source_id] == 'Note'
    ap "PROCESSING NOTES..."
    objects = NoteMapper.map_json(params[:objects])
    ap objects
  else
    objects = params[:objects]
  end
  
  source_sync.push_objects(objects)
  
  begin
    ap "push_objects_notify called, notifying observer for #{params[:source_id]}"
    klass = Object.const_get(params[:source_id].capitalize)
    klass.notify_api_pushed(params[:user_id]) if klass.respond_to?(:notify_api_pushed)
  rescue Exception => e
    ap e
    log e.inspect
  end
end


# {
#   "api_token" => "6f609e8a5c1c4baa96c7d520375ab7a6",
#   "user_id" => "dhamo.raj",
#        "objects" => {
#          "b9930e04-f94b-e011-93bf-0050569c7cfe" => {
#              "cssi_lastactivitydate" => "03/22/2011 04:49:36 PM"
#          }
#      },
#      "source_id" => "Opportunity"
#  }