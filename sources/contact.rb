class Contact < SourceAdapter
  
  def initialize(source,credential)
    @contact_url = "#{CONFIG[:crm_path]}contact"
    super(source,credential)
  end
 
  def login
    @token = Store.get_value("username:#{current_user.login.downcase}:token")
    @initialized_key = "username:#{current_user.login.downcase}:contact:initialized"
  end
 
  def query(params=nil)
    unless Store.get_value(@initialized_key) == 'true'
      puts "INITIALIZING USER CONTACTS for #{current_user.login.downcase}"
      parsed_values = JSON.parse(RestClient.post(@contact_url,
          {:token => @token}, 
          :content_type => :json
        )
      )
      @result = parsed_values.reduce({}){|sum, value| sum[value['contactid']] = value; sum }
      ap @result
    end
  end
 
  def sync
    unless Store.get_value(@initialized_key) == 'true'
      super
      Store.put_value(@initialized_key, 'true')
    end
  end
 
  def create(create_hash,blob=nil)
    
  end
 
  def update(attributes)
    puts "UPDATE CONTACT"
    result = RestClient.post("#{@contact_url}/update", 
      :token => @token, 
      :attributes => attributes.to_json
    ).body
    ap result
    result
  end
 
  def delete(object_id)
   
  end
 
  def logoff
  end
end