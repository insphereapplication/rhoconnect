class UserUtil
  class << self
    def get_crm_id(user_id)
      Store.get_value("username:#{user_id}:crm_user_id")
    end
    
    def disabled_at(user_id)
      time = Store.db.hget(disabled_users_key, user_id)
      time ? Time.at(time.to_i) : nil
    end
    
    def enabled?(user_id)
      disabled_at(user_id).nil?
    end
    
    def disabled?(user_id)
      !enabled?(user_id)
    end
    
    def enable(user_id)
      set_crm_mobile_user_flag(user_id,true)
      Store.db.hdel(disabled_users_key, user_id)
    end
    
    def disable(user_id)
      set_crm_mobile_user_flag(user_id,false)
      Store.db.hset(disabled_users_key, user_id, Time.now.to_i)
    end
    
    def enable_if_disabled(user_id)
      enable(user_id) if disabled?(user_id)
    end
    
    def disable_if_enabled(user_id)
      disable(user_id) if enabled?(user_id)
    end
    
    def set_crm_mobile_user_flag(user_id, value)
      crm_id = get_crm_id(user_id)
      InsiteLogger.info("Setting crm mobile user flag to #{value} for user #{user_id} w/ ID #{crm_id}")
      RestClient.post("#{CONFIG[:crm_path]}/session/SetMobileUser", { :userid => crm_id, :value => value.to_s }) if crm_id
    end
    
    def disabled_users_key
      "disabled_users"
    end
  end
end