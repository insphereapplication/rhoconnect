
class OpportunityMapper < Mapper
  CLIENT_ONLY_FIELDS = ['temp_id',ConflictManagementUtil::CLIENT_UPDATE_TIMESTAMP_FIELD]

  def map_data_from_client(data, mapper_context={})
    data.reject!{|k,v| CLIENT_ONLY_FIELDS.include?(k)}
    data['cssi_fromrhosync'] = 'true'
    
    if mapper_context[:user_id]
      data['ownerid'] = {:type => 'systemuser', :id => mapper_context[:user_id]}
    end
    
    data  
  end
  
  def map_from_source_hash(opportunity_mapper)
    opportunity_mapper.map! do |value| 
      #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
      #these fields are not modified from rhodes and should only be injected in map_data_from_client as needed

      value.reject!{|k,v|  ['ownerid', 'temp_id'].include?(k) }
      
      # for 2.0 Iteration 1 only!
      # Greg Norz - 2011-06-13 - Leaving this commented in here for now in case we need it for iteration 2. It listed as a merge conflict.
      #value.reject!{|k,v|  ['opportunityratingcode', 'actualclosedate'].include?(k) }

      value
    end
    opportunity_mapper.reduce({}){|sum, value| sum[value["opportunityid"]] = value if value; sum }
  end

end