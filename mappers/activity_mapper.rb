
class ActivityMapper < Mapper
  def map_from_source_hash(activity_array)
    activity_array.map! do |value| 
      parentprops = value['regardingobjectid'] 
      value.reject!{|k,v| k == 'regardingobjectid'}
      value.merge({'parent_id' => parentprops['id'], 'parent_type' => parentprops['type']}) unless parentprops.blank?
    end
    activity_array.reduce({}){|sum, value| sum[value["activityid"]] = value if value; sum }
  end 
  
  def self.map_data_from_client(data)
    data.merge!({
      'regardingobjectid' => {
          'type' => data['parent_type'],
          'id' => data['parent_id']
        }
      })
    data.reject!{|k,v| ['parent_id', 'parent_type'].include?(k)}
  end
end