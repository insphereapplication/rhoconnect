class AppInfo < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
  end
 
  def query(params=nil)
    app_info_config = CONFIG[:app_info]
    
    # For backward compatibility, "apple_upgrade_url" and "android_upgrade_url" are used for the forced upgrade URLs
    @result = { "1" => { :min_required_version => app_info_config[:min_required_version], :apple_upgrade_url => app_info_config[:apple_force_upgrade_url], :android_upgrade_url => app_info_config[:android_force_upgrade_url] } }
    
    # Uncomment this (and delete the above line) when we're ready to deploy soft upgrade
    # @result = { "1" => { :min_required_version => app_info_config[:min_required_version], 
    #                      :latest_version => app_info_config[:latest_version],
    #                      :apple_upgrade_url => app_info_config[:apple_force_upgrade_url],
    #                      :android_upgrade_url => app_info_config[:android_force_upgrade_url],
    #                      :apple_soft_upgrade_url => app_info_config[:apple_soft_upgrade_url],
    #                      :android_soft_upgrade_url => app_info_config[:android_soft_upgrade_url],
    #                      :mobile_crypt_key => app_info_config[:mobile_crypt_key]  } }
    
    InsiteLogger.info(:format_and_join => ["Result of AppInfo query: ", @result])
  end
 
  def sync
    super
  end
 
  def create(create_hash,blob=nil)
  end
 
  def update(update_hash)
  end
 
  def delete(delete_hash)
  end
 
  def logoff
  end
end