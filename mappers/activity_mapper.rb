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
  #   "api_token" => "6f609e8a5c1c4baa96c7d520375ab7a6",
  #   "user_id" => "dhamo.raj",
  #        "objects" => {
  #          "b9930e04-f94b-e011-93bf-0050569c7cfe" => {
  #                "cssi_lastactivitydate" => "03/22/2011 04:49:36 PM"
  #                "regardingobjectid" => "{
  #                   'type' => "asdf"
  #                   'id' => '123'
  #               }
  #          }
  #      },
  #      "source_id" => "Opportunity"
  #  }
  
  # {
  #       "parent_type" => "Opportunity",
  #              "type" => "PhoneCall",
  #         "parent_id" => "840af314-b246-e011-93bf-0050569c7cfe"
  # }
  
  # {
  #         "statecode" => "Completed",
  #                "id" => "89d67d58-9454-e011-93bf-0050569c7cfe",
  #      "scheduledend" => "2011-03-22 10:07:34 -0500"
  #  }
  
  
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