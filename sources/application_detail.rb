class ApplicationDetail < SourceAdapter

  # proxy util mixin
  include ProxyUtil
  
  def initialize(source,credential)
    @application_detail_url = "#{CONFIG[:crm_path]}application"
    @proxy_create_url = "#{@application_detail_url}/create"
    @proxy_update_url = "#{@application_detail_url}/update"
    @proxy_delete_url = "#{@application_detail_url}/delete"
    super(source,credential)
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      UserUtil.enable_if_disabled(current_user.login)
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:application_detail:initialized"
      @user_id_key = "username:#{current_user.login.downcase}:crm_user_id"
    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'
        InsiteLogger.info "QUERY FOR APPLICATION DETAILS FOR #{current_user.login}"
        ExceptionUtil.context(:current_user => current_user.login)
        res = RestClient.post(@application_detail_url, 
                                {:username => @username,
                                 :password => @password},
                                 :content_type => :json)
                                            
        @result = Mapper.map_source_data(res, 'ApplicationDetail')
        
        ExceptionUtil.context(:result => @result)
        InsiteLogger.info @result
      end
    end
  end
 
  def sync
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'  
        super
        Store.put_value(@initialized_key, 'true')
      end
    end
  end
 
  def create(create_hash,blob=nil)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "CREATE APPLICATION DETAIL"
      ExceptionUtil.context(:current_user => current_user.login, :create_hash => create_hash)
      
      result = proxy_create(create_hash)
      
      InsiteLogger.info result
      result
    end
  end
 
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "UPDATE APPLICATION DETAIL"

      ExceptionUtil.context(:current_user => current_user.login, :update_hash => update_hash)
            
      result = proxy_update(update_hash)
      
      InsiteLogger.info result
      result
    end
  end
 
  def delete(delete_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "DELETE APPLICATION DETAIL"
      ExceptionUtil.context(:current_user => current_user.login, :delete_hash => delete_hash)
      
      mapped_hash = { 'cssi_applicationid' => delete_hash['id'] };
      
      result = proxy_delete(mapped_hash)
      
      InsiteLogger.info result
      ExceptionUtil.context(:result => result)
    end
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end
end