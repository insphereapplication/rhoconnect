class AppInfo < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
  end
 
  def query(params=nil)
    app_info_config = CONFIG[:app_info]
    
    # For backward compatibility, "apple_upgrade_url" and "android_upgrade_url" are used for the forced upgrade URLs
    
    # Retrieve static values from the settings.yml 
    static_app_info_attrs = { 'min_required_version' => app_info_config[:min_required_version],
                              'latest_version' => app_info_config[:latest_version],
                              'apple_upgrade_url' => app_info_config[:apple_force_upgrade_url],
                              'android_upgrade_url' => app_info_config[:android_force_upgrade_url] ,
                              'model_limits' => app_info_config[:model_limits]}
    
    # Uncomment this (and delete the above line) when we're ready to deploy soft upgrade
    # static_app_info_attrs = { 'min_required_version' => app_info_config[:min_required_version], 
    #                      'latest_version' => app_info_config[:latest_version],
    #                      'apple_upgrade_url' => app_info_config[:apple_force_upgrade_url],
    #                      'android_upgrade_url' => app_info_config[:android_force_upgrade_url],
    #                      'apple_soft_upgrade_url' => app_info_config[:apple_soft_upgrade_url],
    #                      'android_soft_upgrade_url' => app_info_config[:android_soft_upgrade_url],
    #                      'mobile_crypt_key' => app_info_config[:mobile_crypt_key]  }
   
   
   # The only dynamic value in this model is the PIN -- all other values (min versions, upgrade URLS) are static and should be merged in from the settings.yml
    md = RedisUtil.get_md('AppInfo', current_user.login)
    md["1"] ||= {}
    md["1"].merge!(static_app_info_attrs)
    @result = md
    
    InsiteLogger.info(:format_and_join => ["Result of AppInfo query: ", @result])
  end
 
  def sync
    super
  end
 
  def create(create_hash,blob=nil)
  end
 
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      ExceptionUtil.context(:current_user => current_user.login, :update_hash => update_hash)
      InsiteLogger.info(:format_and_join => ["Result of AppInfo update: ", update_hash])
      UpdateUtil.push_update(@source, update_hash)
    end
  end
 
  def delete(delete_hash)
  end
 
  def logoff
  end
end