class Note < SourceAdapter
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @note_url = "#{CONFIG[:crm_path]}annotation"
      super(source,credential)
    end
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
          
      @initialized_key = "username:#{current_user.login.downcase}:note:initialized"
    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'
        InsiteLogger.info "NOTE QUERY"
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
      InsiteLogger.info create_hash
      InsiteLogger.info "#{@note_url}/create"
      mapped_hash = NoteMapper.map_data_from_client(create_hash.clone)
      InsiteLogger.info mapped_hash
    
      result = RestClient.post("#{@note_url}/create", 
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
      result = JSON.parse(RestClient.post("#{@note_url}/update", 
          {:username => @username, 
          :password => @password,
          :attributes => attributes.to_json}
        ).body)

      UpdateUtil.push_update(@source, update_hash)
    end
  end
 
  def delete(object_id)
  end
 
  def logoff
  end
end