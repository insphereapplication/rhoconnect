
# Rhosync::Server.api :push_objects_notify do |params,user|
#   source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
#   source_sync = SourceSync.new(source)
#   source_sync.push_objects(params[:objects])
#   
#   begin
#     puts "push_objects_notify called, notifying observer for #{params[:source_id]}"
#     klass = Object.const_get(params[:source_id])
#     if klass
#       klass.api_pushed(params[:user_id]) if klass.respond_to?(:api_pushed)
#     else
#       puts "Unable to create class object for #{params[:source_id]}"
#     end
#   rescue Exception => e
#     puts e.inspect
#   end
# end