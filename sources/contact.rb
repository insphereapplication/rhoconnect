require 'helpers/crypto'

class Contact < SourceAdapter
  
  def initialize(source,credential)
    Exceptional.rescue_and_reraise do
      @contact_url = "#{CONFIG[:crm_path]}contact"
      super(source,credential)
    end
  end
 
  def login
    Exceptional.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:contact:initialized"

    end
  end
 
  def query(params=nil)
    Exceptional.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'
        puts "INITIALIZING USER CONTACTS for #{current_user.login.downcase}"
        Exceptional.context(:current_user => current_user.login )
        res = RestClient.post(@contact_url,
          {:username => @username, 
            :password => @password},
            :content_type => :json
        )
        
        @result = Mapper.map_source_data(res, 'Contact')
        
        Exceptional.context(:result => @result )
        ap @result
      end
    end
  end
 
  def sync
    Exceptional.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'
        super
        Store.put_value(@initialized_key, 'true')
      end
    end
  end
 
  def create(create_hash,blob=nil)
    
  end
  
  def update(update_hash)
    Exceptional.rescue_and_reraise do
      puts "UPDATE CONTACT"
      Exceptional.context(:current_user => current_user.login )
      
      mapped_hash = ContactMapper.map_data_from_client(update_hash.clone)
      
      result = RestClient.post("#{@contact_url}/update", 
          {:username => @username, 
          :password => @password,
          :attributes => mapped_hash.to_json}
      ).body
      
      ap result
      Exceptional.context(:result => result )
      result
    end
  end
 
  def delete(object_id)
   
  end
 
  def logoff
  end
end