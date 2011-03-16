class Note < SourceAdapter
  def initialize(source,credential)
    @note_url = "#{CONFIG[:crm_path]}note"
    super(source,credential)
  end
 
  def login
    @token = Store.get_value("username:#{current_user.login}:token")
    @initialized_key = "username:#{current_user.login}:note:initialized"
  end
 
  def query(params=nil)
    unless Store.get_value(@initialized_key) == 'true'
      parsed_values = JSON.parse(RestClient.post(@note_url,
          {:token => @token}, 
          :content_type => :json
        )
      )
      @result = parsed_values.reduce({}){|sum, value| sum[value['noteid']] = value['note']; sum }
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