require 'helpers/crypto'

class Contact < SourceAdapter
  
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @contact_url = "#{CONFIG[:crm_path]}contact"
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
    
  end
  
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "UPDATE CONTACT"
      ExceptionUtil.context(:current_user => current_user.login )
      
      mapped_hash = ContactMapper.map_data_from_client(update_hash.clone)
      
      result = RestClient.post("#{@contact_url}/update", 
          {:username => @username, 
          :password => @password,
          :attributes => mapped_hash.to_json}
      ).body
      
      InsiteLogger.info result.info
      ExceptionUtil.context(:result => result )
      result
    end
  end
 
  def delete(object_id)
   
  end
 
  def logoff
  end
end