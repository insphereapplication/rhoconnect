require 'ap'

class ActivityMapper < Mapper
  def self.map_json(data)
    parsed_values = JSON.parse(data)
    parsed_values.map! do |value| 
      parentprops = value['regardingobjectid'] 
      value.reject!{|k,v| k == 'regardingobjectid'}
      value.merge({'parent_id' => parentprops['id'], 'parent_type' => parentprops['type']})
    end
    parsed_values.reduce({}){|sum, value| sum[value["activityid"]] = value; sum }
  end 
end