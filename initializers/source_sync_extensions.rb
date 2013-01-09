# Dwayne Smith 01/09/2013  - This code is no longer being used for Rhoconnect.  As far as I can tell we where over writing the push_objects update in rhosync so that 
# update for items that did not exist would be rejects instead of created.  This should be handled by checking in source update for existence before accepting
# the change.  I am commenting out the code.

# module Rhoconnect
#   class SourceSync    
#     def push_object_updates(data)
#       rejected_creates = []
#       @source.lock(:md) do |s|
#         doc = s.get_data(:md)
#         Store.db.pipelined do
#           data.each do |key,value|
#             existing_record = doc[key]
#             if existing_record
#               value.each do |attrib,value|
#                 existing_value = existing_record[attrib]
#                 existing_value = setelement(key,attrib,existing_value) if existing_value 
#                 new_value = setelement(key,attrib,value)
#                 if existing_value.nil? or existing_value != new_value
#                   Store.db.srem(s.docname(:md), existing_value) if existing_value
#                   Store.db.sadd(s.docname(:md), new_value)
#                 end
#               end
#             else
#               rejected_creates.push(key)
#             end
#           end
#         end
#       end  
#       rejected_creates
#     end
#   end
# end