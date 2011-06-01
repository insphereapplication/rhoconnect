
class OpportunityMapper < Mapper
  OPPORTUNITY_CONFLICT_FIELDS = ['statuscode', 'statecode', 'cssi_lastactivitydate']
  def self.map_data_from_client(data, current_user)
    if data['cssi_lastactivitydate'] && data['id'] && current_user
      opp_id = data['id']
      InsiteLogger.info "Checking for data conflicts on opportunity #{opp_id}"
      redis_opp = RedisUtil.get_model('Opportunity', current_user.login, opp_id)
      redis_last_activity_date = Time.parse(redis_opp['cssi_lastactivitydate'])
      client_last_activity_date = Time.parse(data['cssi_lastactivitydate'])
    
      if (redis_last_activity_date > client_last_activity_date)
        InsiteLogger.info "Found conflict for opportunity #{opp_id}, rejecting relevant client data."
        data.reject!{|key, value| OPPORTUNITY_CONFLICT_FIELDS.include?(key)}
      else
        InsiteLogger.info "No conflicts found for opp #{opp_id}"
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