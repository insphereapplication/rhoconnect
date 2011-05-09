
class OpportunityMapper < Mapper
  OPPORTUNITY_CONFLICT_FIELDS = [:statuscode, :statecode, :cssi_lastactivitydate]
  def self.map_data_from_client(data, current_user=nil)
    if data[:cssi_lastactivitydate]
      redis_opp = RedisUtil.get_model('Opportunity', current_user.login, (data.with_indifferent_access['id'] || data.with_indifferent_access['opportunityid']))
      redis_last_activity_date = Time.parse(redis_opp[:cssi_lastactivitydate])
      client_last_activity_date = Time.parse(data[:cssi_lastactivitydate])
    
      if (redis_last_activity_date > client_last_activity_date)
        data.reject!{|key, value| OPPORTUNITY_CONFLICT_FIELDS.include?(key)}
      end
    end
    data  
  end
  
  def map_from_source_hash(opportunity_mapper)
    opportunity_mapper.map! do |value| 
      #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
      #these fields are not modified from rhodes and should only be injected in map_data_from_client as needed
      value.reject!{|k,v|  ['ownerid'].include?(k) }
      value
    end
    opportunity_mapper.reduce({}){|sum, value| sum[value["opportunityid"]] = value if value; sum }
  end

end