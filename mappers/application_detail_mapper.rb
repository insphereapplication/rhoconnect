
class ApplicationDetailMapper < Mapper

  def self.map_create_data_from_client(data)    
    data.merge!({
      "cssi_opportunityid" => {
        "id" => data['opportunity_id'], 
        "type"=>"opportunity"
      }
    })    
    data.reject!{|k,v| ['opportunity_id'  ,'temp_id'].include?(k)}
    data  
  end

  def self.map_update_data_from_client(data)
    data.reject!{|k,v| ['opportunity_id'  ,'temp_id'].include?(k)}
    data  
  end
  
  def map_from_source_hash(app_detail_mapper)
    app_detail_mapper.map! do |value|    
      opportunity_id = value['cssi_opportunityid']
      if opportunity_id
        value.reject!{|k,v| k == 'cssi_opportunityid'}
        value.merge!({'opportunity_id' => opportunity_id['id']}) unless opportunity_id.blank?
      end    
      #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
      #these fields are not modified from rhodes and should only be injected in map_data_from_client as needed
      value.reject!{|k,v|  ['ownerid', 'temp_id'].include?(k) }
      value
    end
    app_detail_mapper.reduce({}){|sum, value| sum[value["cssi_applicationid"]] = value if value; sum }
  end
end