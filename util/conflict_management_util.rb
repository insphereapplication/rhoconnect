require 'ap'

class ConflictManagementUtil
  OPPORTUNITY_CONFLICT_FIELDS = ['statuscode', 'statecode', 'cssi_statusdetail', 'cssi_lastactivitydate']
  def self.manage_opportunity_conflicts(updated_opportunity, current_user)
    if updated_opportunity['cssi_lastactivitydate']
      opp_id = updated_opportunity['id']
      InsiteLogger.info "Checking for data conflicts on opportunity #{opp_id} for user #{current_user.login}"
      
      redis_opp = RedisUtil.get_model('Opportunity', current_user.login, opp_id)
      
      redis_last_activity_date = Time.parse(redis_opp['cssi_lastactivitydate'])
      client_last_activity_date = Time.parse(updated_opportunity['cssi_lastactivitydate'])
      
      InsiteLogger.info "Redis last activity date = #{redis_last_activity_date}"
      InsiteLogger.info "Client last activity date = #{client_last_activity_date}"

      if (redis_last_activity_date > client_last_activity_date)
        InsiteLogger.info "Found conflict for opportunity #{opp_id}, rejecting relevant client data."
        updated_opportunity.reject!{|key, value| OPPORTUNITY_CONFLICT_FIELDS.include?(key)}
      else
        InsiteLogger.info "No conflicts found for opp #{opp_id}"
      end
    end
  end
end