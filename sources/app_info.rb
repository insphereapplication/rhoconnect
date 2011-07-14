class AppInfo < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
  end
 
  def query(params=nil)
    settings = YAML::load_file('settings/settings.yml')
    ap "*** Settings file = #{settings[:global][:app_info].inspect}"
    mrv = settings[:global][:app_info][:min_required_version]
    lv = settings[:global][:app_info][:latest_version]
    
    apple_force_upgrade_url = settings[:global][:app_info][:apple_force_upgrade_url]
    android_force_upgrade_url = settings[:global][:app_info][:android_force_upgrade_url]
    
    apple_soft_upgrade_url = settings[:global][:app_info][:apple_soft_upgrade_url]
    android_soft_upgrade_url = settings[:global][:app_info][:android_soft_upgrade_url]
    mobile_crypt_key = settings[:global][:app_info][:mobile_crypt_key]
    
    ap "*** Minimum required version is #{mrv} ***"
    ap "*** Latest version is #{lv} ***"
    ap "*** Apple Force Upgrade URL is #{apple_force_upgrade_url} ***"
    ap "*** Android Force Upgrade URL is #{android_force_upgrade_url} ***"
    
    ap "*** Apple Soft Upgrade URL is #{apple_soft_upgrade_url} ***"
    ap "*** Android Soft Upgrade URL is #{android_soft_upgrade_url} ***"
    
    # For backward compatibility, "apple_upgrade_url" and "android_upgrade_url" are used for the forced upgrade URLs
    @result = { "1" => { :min_required_version => mrv, :apple_upgrade_url => apple_force_upgrade_url, :android_upgrade_url => android_force_upgrade_url } }
     
    # Uncomment this (and delete the above line) when we're ready to deploy soft upgrade
    # @result = { "1" => { :min_required_version => mrv, 
    #                      :latest_version => lv,
    #                      :apple_upgrade_url => apple_force_upgrade_url,
    #                      :android_upgrade_url => android_force_upgrade_url,
    #                      :apple_soft_upgrade_url => apple_soft_upgrade_url,
    #                      :android_soft_upgrade_url => android_soft_upgrade_url,
    #                      :mobile_crypt_key => mobile_crypt_key  } }
  
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