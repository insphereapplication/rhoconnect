class ApplicationDetail < SourceAdapter
  def initialize(source,credential)
    @application_detail_url = "#{CONFIG[:crm_path]}application"
    super(source,credential)
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
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
        InsiteLogger.info "QUERY FOR APPLICATION DETAILS for #{current_user.login.downcase}"
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
      ExceptionUtil.context(:current_user => current_user.login)
      
      mapped_hash = ApplicationDetailMapper.map_create_data_from_client(create_hash.clone)
      
      ap "mappped_hash = #{mapped_hash.inspect}"
      ap "JSON = #{mapped_hash.to_json}"
      
      result = RestClient.post("#{@application_detail_url}/create",
          {:username => @username,
           :password => @password,
           :attributes => mapped_hash.to_json}
      ).body
      
      InsiteLogger.info result
      result
    end
  end
 
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "UPDATE APPLICATION DETAIL"
      ExceptionUtil.context(:current_user => current_user.login )
      
      # mark this update so the plugin won't unnecessarily push it back
      update_hash['cssi_fromrhosync'] = 'true'
      
      mapped_hash = ApplicationDetailMapper.map_update_data_from_client(update_hash.clone)
      
      result = RestClient.post("#{@application_detail_url}/update", 
          {:username => @username, 
          :password => @password,
          :attributes => mapped_hash.to_json}
      ).body
      
      UpdateUtil.push_update(@source, update_hash)
      
      InsiteLogger.info result
      ExceptionUtil.context(:result => result )
      result
    end
  end
 
  def delete(delete_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "DELETE APPLICATION DETAIL"
      ExceptionUtil.context(:current_user => current_user.login)
      
      mapped_hash = { 'cssi_applicationid' => delete_hash['cssi_applicationid'] };
      
      result = RestClient.post("#{@application_detail_url}/delete",
          {:username => @username,
           :password => @password,
           :attributes => mapped_hash.to_json}
      ).body
      
      InsiteLogger.info result
      ExceptionUtil.context(:result => result)
    end
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end
end