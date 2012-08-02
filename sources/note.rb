class Note < SourceAdapter

  # proxy util mixin
  include ProxyUtil
  include ReplaceTempID
  
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @note_url = "#{CONFIG[:crm_path]}annotation"
      @proxy_update_url = "#{@note_url}/update"
      @proxy_create_url = "#{@note_url}/create"
      super(source,credential)
    end
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      UserUtil.enable_if_disabled(current_user.login)
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
          
      @initialized_key = "username:#{current_user.login.downcase}:note:initialized"
    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'
        InsiteLogger.info "QUERY FOR NOTES FOR #{current_user.login}"
        res = RestClient.post(@note_url,
            {:username => @username, 
            :password => @password},
            :content_type => :json
          )
        @result = Mapper.map_source_data(res, 'Note')
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
      InsiteLogger.info "CREATE NOTE"
      ExceptionUtil.context(:current_user => current_user.login, :create_hash => create_hash)

      create_hash = replace_with_guid(create_hash,"parent_id",create_hash['parent_type'])
      result = proxy_create(create_hash)
      
      InsiteLogger.info result
      result
    end
  end
 
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "UPDATE NOTE"
      ExceptionUtil.context(:current_user => current_user.login, :update_hash => update_hash )
            
      result = proxy_update(update_hash)
      
      InsiteLogger.info result
      ExceptionUtil.context(:result => result )
      result
    end
  end
 
  def delete(object_id)
  end
 
  def logoff
  end
end