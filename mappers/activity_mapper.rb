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
  
  # {
  #       "parent_type" => "Opportunity",
  #              "type" => "PhoneCall",
  #         "parent_id" => "840af314-b246-e011-93bf-0050569c7cfe"
  # }
  
   # {
   #       "regardingobjectid" => "{
   #          'type' => "asdf"
   #          'id' => '123'
   #        }
   # }
  
  # {'parent_id' => parentprops['id'], 'parent_type' => parentprops['type']}
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