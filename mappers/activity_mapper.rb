
class ActivityMapper < Mapper
  def map_from_source_hash(activity_array)
    activity_array.map! do |value| 
      parentprops = value['regardingobjectid'] 
      unless parentprops.nil?
        value.reject!{|k,v| k == 'regardingobjectid'}
        value.merge!({'parent_id' => parentprops['id'], 'parent_type' => Mapper.convert_type_name(parentprops['type'])}) unless parentprops.blank?
      end
      
      recipient_field_name = ActivityMapper.get_recipient_field_name(value['type'])
      recipient_value = value[recipient_field_name]
      unless recipient_value.nil?
        value.merge!({'parent_contact_id' => recipient_value[0]['id']}) unless recipient_value.blank?
        value.reject!{|k,v| k == recipient_field_name}
      end
      
      #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
      #these fields are not modified from rhodes and should only be injected in map_data_from_client as needed
      value.reject!{|k,v|  ['cssi_skipdispositionworkflow','organizer','from','cssi_fromrhosync'].include?(k) }
      value
    end
    activity_array.reduce({}){|sum, value| sum[value["activityid"]] = value if value; sum }
  end
  
  def self.map_data_from_client(data)
    if data['parent_type'] || data['parent_id']
      data.merge!({
        'regardingobjectid' => {
            'type' => data['parent_type'],
            'id' => data['parent_id']
          }
        })
      data.reject!{|k,v| ['parent_id', 'parent_type'].include?(k)}
    end
    
    data.merge!({
      'cssi_skipdispositionworkflow' => 'true'
    }) unless data['cssi_disposition'].nil?
    
    if data['parent_contact_id']
      data.merge!({
          get_recipient_field_name(data['type']) => [{
            'type' => 'contact',
            'id' => data['parent_contact_id']
          }]
        }) unless data['parent_contact_id'].blank?
      data.reject!{|k,v| k == 'parent_contact_id'}
    end
    
    data
  end
  
  def self.get_recipient_field_name(type)
    (type.downcase == 'phonecall') ? 'to' : 'requiredattendees' unless type.blank?
  end
end