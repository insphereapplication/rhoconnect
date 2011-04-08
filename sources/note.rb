class Note < SourceAdapter
  def initialize(source,credential)
    Exceptional.rescue_and_reraise do
      @note_url = "#{CONFIG[:crm_path]}annotation"
      super(source,credential)
    end
  end
 
  def login
    Exceptional.rescue_and_reraise do
      @token = Store.get_value("username:#{current_user.login.downcase}:token")
      @initialized_key = "username:#{current_user.login.downcase}:note:initialized"
    end
  end
 
  def query(params=nil)
    Exceptional.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'
        ap "NOTE QUERY"
        res = RestClient.post(@note_url,
            {:token => @token}, 
            :content_type => :json
          )
        @result = Mapper.map_source_data(res, 'Note')
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
    Exceptional.rescue_and_reraise do
      puts "CREATE NOTE"
      ap create_hash
      ap "#{@note_url}/create"
      ap @token
      mapped_hash = NoteMapper.map_data_from_client(create_hash.clone)
      ap mapped_hash
    
      result = RestClient.post("#{@note_url}/create", 
          :token => @token, 
          :attributes => mapped_hash.to_json
        ).body
      ap result
    
      result
    end
  end
 
  def update(update_hash)
    Exceptional.rescue_and_reraise do
      result = JSON.parse(RestClient.post("#{@note_url}/update", 
          :token => @token, 
          :attributes => attributes.to_json
        ).body)
    end
  end
 
  def delete(object_id)
  end
 
  def logoff
  end
end