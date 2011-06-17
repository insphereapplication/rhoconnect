class Contact < SourceAdapter

  # proxy util mixin
  include ProxyUtil
  
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @contact_url = "#{CONFIG[:crm_path]}contact"
      @proxy_update_url = "#{@contact_url}/update"
      @proxy_create_url = "#{@contact_url}/create"
      super(source,credential)
    end
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:contact:initialized"

    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'
        InsiteLogger.info "INITIALIZING USER CONTACTS for #{current_user.login.downcase}"
        ExceptionUtil.context(:current_user => current_user.login )
        res = RestClient.post(@contact_url,
          {:username => @username, 
            :password => @password},
            :content_type => :json
        )
        
        @result = Mapper.map_source_data(res, 'Contact')
        
        ExceptionUtil.context(:result => @result )
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
      InsiteLogger.info "CREATE CONTACT"
      ExceptionUtil.context(:current_user => current_user.login, :create_hash => create_hash)
      
      if (create_hash['contactid'].upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
        #contact already exists in CRM; do not push to CRM. Only create it on the device.
        result = create_hash['contactid']
      else  
        #new contact created on the device; call proxy_create to push new contact to CRM
        result = proxy_create(create_hash)     
      end
      
      InsiteLogger.info result
      result
    end
  end
  
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "UPDATE CONTACT"
      ExceptionUtil.context(:current_user => current_user.login, :update_hash => update_hash )
      
      result = proxy_update(update_hash)
      
      InsiteLogger.info result
      result
    end
  end
 
  def delete(object_id)
   
  end
 
  def logoff
  end
end