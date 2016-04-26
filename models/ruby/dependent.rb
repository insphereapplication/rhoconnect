class Dependent < Rhoconnect::Model::Base

  # proxy util mixin
  include ProxyUtil
  include ReplaceTempID
  
  def initialize(source)
    ExceptionUtil.rescue_and_reraise do
      @dependent_url = "#{CONFIG[:crm_path]}dependents"
      @proxy_update_url = "#{@dependent_url}/update"
      @proxy_create_url = "#{@dependent_url}/create"
      @proxy_delete_url = "#{@dependent_url}/delete"
      super(source)
    end
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      UserUtil.enable_if_disabled(current_user.login)
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:dependent:initialized"
    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'
        InsiteLogger.info "QUERY FOR DEPENDENTS FOR #{current_user.login}"
        ExceptionUtil.context(:current_user => current_user.login)
        res = RestClient.post(@dependent_url, {:username => @username,
                                            :password => @password},
                                            :content_type => :json)
                                            
        @result = Mapper.map_source_data(res, 'Dependent')
        
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
      InsiteLogger.info "CREATE DEPENDENT"
      ExceptionUtil.context(:current_user => current_user.login, :create_hash => create_hash)
      create_hash = replace_with_guid(create_hash,"contact_id","Contact")
      result = proxy_create(create_hash)
      
      InsiteLogger.info result
      result
    end
  end
 
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "UPDATE DEPENDENT"
      ExceptionUtil.context(:current_user => current_user.login, :update_hash => update_hash )
            
      result = proxy_update(update_hash)
      
      InsiteLogger.info result
      ExceptionUtil.context(:result => result )
      result
    end
  end
 
  def delete(delete_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "DELETE DEPENDENT"
      ExceptionUtil.context(:current_user => current_user.login, :delete_hash => delete_hash)
      
      mapped_hash = { 'cssi_dependentsid' => delete_hash['cssi_dependentsid'] };
      
      result = proxy_delete(mapped_hash)
      
      InsiteLogger.info result
      ExceptionUtil.context(:result => result)
    end
  end
 
  def logoff
    
  end
end