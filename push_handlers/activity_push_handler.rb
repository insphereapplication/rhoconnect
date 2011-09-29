class ActivityPushHandler < PushHandler
  STATUS_FIELDS = ['statecode','statuscode']
  
  COMPLETED_HISTORY_FIELD = '_completed_on_'
  
  def get_update_history_util(user_id)
    UpdateHistoryUtil.new('Activity',user_id)
  end
  
  def handle_push(user_id, push_hash)
    update_history_util = get_update_history_util(user_id)
    push_hash.each do |id,activity|
      if id && activity.select{|key,value| STATUS_FIELDS.include?(key)}.count > 0
        completed_on = update_history_util.last_update(id,COMPLETED_HISTORY_FIELD)
        if completed_on
          # Activity has been lost already, reject statecode & statuscode fields
          InsiteLogger.info "Activity #{id} for user #{user_id} was already marked as complete on #{completed_on}, rejecting statecode & statuscode fields from push."
          activity.reject!{|key,value| STATUS_FIELDS.include?(key)}
        else
          InsiteLogger.debug "Activity #{id} for user #{user_id} has not been completed in the past."
          activity_statecode = (activity['statecode'] || '').downcase
          if activity_statecode == 'completed'
            InsiteLogger.info "Detected completion of activity #{id} for user #{user_id}, touching completion history."
            update_history_util.touch(id,COMPLETED_HISTORY_FIELD)
          end
        end
      else
        InsiteLogger.debug "Push for activity #{id} for user #{user_id} doesn't include updates to status fields."
      end
    end
  end

end