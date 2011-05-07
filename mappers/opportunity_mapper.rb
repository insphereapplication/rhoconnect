class OpportunityMapper
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
end