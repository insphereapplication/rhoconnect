require 'ap'

class ConflictManagementUtil
  OPPORTUNITY_CONFLICT_FIELDS = ['statuscode', 'statecode', 'cssi_statusdetail']
  FIELDS_TO_REJECT_ON_CONFLICT = OPPORTUNITY_CONFLICT_FIELDS + ['cssi_lastactivitydate']
  
  STATUS_HISTORY_FIELD = '_status_'
  
  def self.get_update_history_util(user_id)
    UpdateHistoryUtil.new('Opportunity',user_id)
  end
  
  def self.process_opportunity_push(user_id, push_hash)
    # if the hash being pushed contains any of the conflict fields, make sure to touch the update the timestamp stored in our status history field
    push_hash.each{|opp_id,opp|
      if opp_id && opp.select{|key,value| OPPORTUNITY_CONFLICT_FIELDS.include?(key)}.count > 0
        touch_result = get_update_history_util(user_id).touch(opp_id,STATUS_HISTORY_FIELD)
        InsiteLogger.info "Detected update to opportunity conflict fields for #{user_id}'s opp #{opp_id}, touched update history. Old time: #{touch_result[:prior_update_time]}, new time: #{touch_result[:new_update_time]}"
      else
        InsiteLogger.info "No updates to opportunity conflict fields detected for #{user_id}'s opp #{opp_id}, no need to touch update history."
      end
    }
  end
  
  def self.reject_conflict_fields(update_hash)
    rejected_fields = {}
    update_hash.reject!{|key, value| 
      should_reject = FIELDS_TO_REJECT_ON_CONFLICT.include?(key)
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
    
    last_status_update = get_update_history_util(current_user.login).last_update(opp_id,STATUS_HISTORY_FIELD)
    
    # don't reject anything if redis doesn't have a last activity date for the updated opportunity
    if last_status_update.nil?
      InsiteLogger.info "No prior update found, therefore no conflicts found for opp #{opp_id}."
      return updated_opportunity
    end
  
    client_last_activity_date = Time.parse(updated_opportunity['cssi_lastactivitydate'])
    
    InsiteLogger.info "Last known status update = #{last_status_update}"
    InsiteLogger.info "Client last activity date = #{client_last_activity_date}"
    
    # If the difference between the redis last activity date and the client's last activity date is greater than the configured threshold, reject the update
    if (last_status_update - client_last_activity_date > CONFIG[:conflict_management_threshold])
      updated_opportunity,rejected_fields = reject_conflict_fields(updated_opportunity)
      InsiteLogger.info(:format_and_join => ["Found conflict for opportunity #{opp_id}, rejected fields: ", rejected_fields])
    else
      InsiteLogger.info "No conflicts found for opp #{opp_id}"
    end
    
    updated_opportunity
  end
end