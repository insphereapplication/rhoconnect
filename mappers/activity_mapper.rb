
class ActivityMapper < Mapper
  def map_from_source_hash(activity_array)
    activity_array.map! do |value| 
      parentprops = value['regardingobjectid'] 
      unless parentprops.blank?
        value.reject!{|k,v| k == 'regardingobjectid'}
        value.merge!({'parent_id' => parentprops['id'], 'parent_type' => Mapper.convert_type_name(parentprops['type'])})
      end
      #always filter out skip disposition workflow
      #never should be modified from rhodes and should only be injected in map_data_from_client as needed
      value.reject!{|k,v| k == 'cssi_skipdispositionworkflow'}
      value.reject!{|k,v| k == 'organizer'}
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
    data
  end
end