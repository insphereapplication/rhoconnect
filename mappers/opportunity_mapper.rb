
class OpportunityMapper < Mapper
  CLIENT_ONLY_FIELDS = ['temp_id',ConflictManagementUtil::CLIENT_UPDATE_TIMESTAMP_FIELD]

  def map_data_from_client(data, mapper_context={})
    data.reject!{|k,v| CLIENT_ONLY_FIELDS.include?(k)}
    data['cssi_fromrhosync'] = 'true'
    
    current_owner = data['ownerid'].blank?  ? mapper_context[:user_id] : data['ownerid']
    
    if current_owner
      data['ownerid'] = {:type => 'systemuser', :id => current_owner }
    end
    
    if data['createdon']
        data['overriddencreatedon'] = data['createdon']
     end
     data.reject!{|k,v|  ['createdon'].include?(k) }
    data  
  end
  
  def map_from_source_hash(opportunity_mapper)
    opportunity_mapper.map! do |value| 
      #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
      #these fields are not modified from rhodes and should only be injected in map_data_from_client as neede
      
      value.reject!{|k,v|  ['temp_id','overriddencreatedon'].include?(k) }

      # the owner comes across as complex type with id type and name we convert it to id only
      value['ownerid'] = value['ownerid']['id'] if value['ownerid']
          
      value
    end
    opportunity_mapper.reduce({}){|sum, value| sum[value["opportunityid"]] = value if value; sum }
  end

end