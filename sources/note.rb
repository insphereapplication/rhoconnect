class Note < SourceAdapter
  def initialize(source,credential)
    @note_url = "#{CONFIG[:crm_path]}annotation"
    super(source,credential)
  end
 
  def login
    @token = Store.get_value("username:#{current_user.login.downcase}:token")
    @initialized_key = "username:#{current_user.login.downcase}:note:initialized"
  end
 
  def query(params=nil)
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
 
  def sync
    unless Store.get_value(@initialized_key) == 'true'
      super
      Store.put_value(@initialized_key, 'true')
    end
  end
 
  def create(create_hash,blob=nil)
    puts "CREATE NOTE"
    ap create_hash
    ap "#{@note_url}/create"
    ap @token
    mapped_hash = NoteMapper.map_data_from_client(create_hash)
    ap mapped_hash
    
    result = RestClient.post("#{@note_url}/create", 
        :token => @token, 
        :attributes => mapped_hash.to_json
      ).body
    ap result
    
    result
  end
 
  def update(update_hash)
    result = JSON.parse(RestClient.post("#{@note_url}/update", 
        :token => @token, 
        :attributes => attributes.to_json
      ).body)
  end
 
  def delete(object_id)
  end
 
  def logoff
  end
end