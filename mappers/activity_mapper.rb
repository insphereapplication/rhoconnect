require 'ap'

class ActivityMapper < Mapper
  def self.map_json(data)
    parsed_values = JSON.parse(data)
    # ap parsed_values
    parsed_values.map! do |value| 
      parentprops = value['regardingobjectid'] 
      value.reject!{|k,v| k == 'regardingobjectid'}
      value.merge({'parent_id' => parentprops['id'], 'parent_type' => parentprops['type']})
    end
    parsed_values.reduce({}){|sum, value| sum[value["activityid"]] = value; sum }
  end 
  
  def self.map_data_from_client(data)
    data.merge!({
      'subject' => 'test', 
      'regardingobjectid' => {
          'type' => data['parent_type'],
          'id' => data['parent_id']
        }
      })
    data.reject!{|k,v| ['parent_id', 'parent_type'].include?(k)}
  end
end