
class OpportunityMapper < Mapper

  def map_data_from_client(data, mapper_context={})
    data.reject!{|k,v| ['temp_id'].include?(k)}
    data['cssi_fromrhosync'] = 'true'
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