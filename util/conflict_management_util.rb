require 'ap'

class ConflictManagementUtil
  OPPORTUNITY_CONFLICT_FIELDS = ['statuscode', 'statecode', 'cssi_statusdetail', 'cssi_lastactivitydate']
  def self.reject_conflict_fields(update_hash)
    rejected_fields = {}
    update_hash.reject!{|key, value| 
      should_reject = OPPORTUNITY_CONFLICT_FIELDS.include?(key)
      rejected_fields[key] = value if should_reject
      should_reject
    }
    [update_hash,rejected_fields]
  end
  
  def self.manage_opportunity_conflicts(updated_opportunity, current_user)

    opp_id = updated_opportunity['id']
    InsiteLogger.info "Checking for data conflicts on opportunity #{opp_id} for user #{current_user.login}"
    
    if updated_opportunity['cssi_lastactivitydate'].blank?
      updated_opportunity,rejected_fields = reject_conflict_fields(updated_opportunity)
      InsiteLogger.info(:format_and_join => ["Update hash does not specify a last activity date, rejected fields: ", rejected_fields])
      return updated_opportunity
    end
    
    # get redis' version of the opportunity being updated
    begin
      redis_opp = RedisUtil.get_model('Opportunity', current_user.login, opp_id)
    rescue RedisUtil::RecordNotFound
      # redis doesn't have an opportunity with this ID, therefore it has been deleted/descoped in CRM (assuming all is well elsewhere)
      # reject the update, delete will be synced back to the client
      InsiteLogger.info "Can't check for conflict as opportunity #{opp_id} does not exist in redis; rejecting all items in update hash."
      return {}
    end
    
    # if the opportunity has been closed already (i.e. on another mobile device or in CRM), reject all fields
    if ['Won', 'Lost'].include?(redis_opp['statecode'])
      InsiteLogger.info "Opportunity #{opp_id} is already closed; rejecting all items in the update hash."
      return {}
    end
    
    # don't reject anything if redis doesn't have a last activity date for the updated opportunity
    if redis_opp['cssi_lastactivitydate'].blank?
      InsiteLogger.info "No prior last activity date found in redis, therefore no conflicts found for opp #{opp_id}."
      return updated_opportunity
    end
    
    redis_last_activity_date = Time.parse(redis_opp['cssi_lastactivitydate'])
  
    client_last_activity_date = Time.parse(updated_opportunity['cssi_lastactivitydate'])
    
    InsiteLogger.info "Redis last activity date = #{redis_last_activity_date}"
    InsiteLogger.info "Client last activity date = #{client_last_activity_date}"

    if (redis_last_activity_date > client_last_activity_date)
      updated_opportunity,rejected_fields = reject_conflict_fields(updated_opportunity)
      InsiteLogger.info(:format_and_join => ["Found conflict for opportunity #{opp_id}, rejected fields: ", rejected_fields])
    else
      InsiteLogger.info "No conflicts found for opp #{opp_id}"
    end
    
    updated_opportunity
  end
end