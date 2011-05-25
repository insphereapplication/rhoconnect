class Dependent < SourceAdapter
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @dependent_url = "#{CONFIG[:crm_path]}dependents"
      super(source,credential)
    end
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:dependent:initialized"
    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do
      #unless Store.get_value(@initialized_key) == 'true'
        InsiteLogger.info "QUERY FOR DEPENDENTS for #{current_user.login.downcase}"
        ExceptionUtil.context(:current_user => current_user.login)
        res = RestClient.post(@dependent_url, {:username => @username,
                                            :password => @password},
                                            :content_type => :json)
                                            
        @result = Mapper.map_source_data(res, 'Dependent')
        
        ExceptionUtil.context(:result => @result)
        InsiteLogger.info @result
      #end
    end
  end
 
  def sync
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'  
        super
        Store.put_value(@initialized_key, 'true')
      end
    end
    super
  end
 
  def create(create_hash,blob=nil)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "CREATE DEPENDENT"
      ExceptionUtil.context(:current_user => current_user.login)
      
      mapped_hash = DependentMapper.map_data_from_client(update_hash.clone)
      
      result = RestClient.post("#{@dependent_url}/create",
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
      InsiteLogger.info "UPDATE DEPENDENT"
      ExceptionUtil.context(:current_user => current_user.login )
      
      mapped_hash = DependentMapper.map_data_from_client(update_hash.clone)
      
      result = RestClient.post("#{@dependent_url}/update", 
          {:username => @username, 
          :password => @password,
          :attributes => mapped_hash.to_json}
      ).body
      
      UpdateUtil.push_objects(@source, update_hash)
      
      InsiteLogger.info result
      ExceptionUtil.context(:result => result )
      result
    end
  end
 
  def delete(delete_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "DELETE DEPENDENT"
      ExceptionUtil.context(:current_user => current_user.login)
      
      mapped_hash = DependentMapper.map_data_from_client(update_hash.clone)
      
      result = RestClient.post("#{@dependent_url}/delete",
          {:username => @username,
           :password => @password,
           :attributes => mapped_hash.to_json}
      ).body
      
      #TODO: Delete from redis?
      
      InsiteLogger.info result
      ExceptionUtil.context(:result => result)
    end
  end
 
  def logoff
    
  end
end