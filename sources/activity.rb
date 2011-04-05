
class Activity < SourceAdapter
  def initialize(source,credential)
    @activity_url = "#{CONFIG[:crm_path]}activity"
    super(source,credential)
  end
 
  def login
    @token = Store.get_value("username:#{current_user.login.downcase}:token")
    @initialized_key = "username:#{current_user.login.downcase}:activity:initialized"
    @user_id_key = "username:#{current_user.login.downcase}:crm_user_id"
  end
 
  def query(params=nil)
    unless Store.get_value(@initialized_key) == 'true'
      ap "ACTIVITY QUERY"
      res = RestClient.post(@activity_url,
          {:token => @token}, 
          :content_type => :json
        )
      @result = Mapper.map_source_data(res, 'Activity')
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
    puts "CREATE ACTIVITY"
    ap create_hash
    ap "#{@activity_url}/create"
    ap @token
    
    #calling clone on the following line is EXTREMELY important - create_hash is passed by reference and is what is going to be committed to the DB
    mapped_hash = ActivityMapper.map_data_from_client(create_hash.clone)
    
    if mapped_hash['type'].downcase == 'appointment'
      mapped_hash['organizer'] = [{:type => 'systemuser', :id => Store.get_value(@user_id_key)}]
    else #phone call
      mapped_hash['from'] = [{:type => 'systemuser', :id => Store.get_value(@user_id_key)}]
    end
    
    mapped_hash['cssi_fromrhosync'] = 'true'
    
    ap mapped_hash.to_json
    result = RestClient.post("#{@activity_url}/create", 
        :token => @token, 
        :attributes => mapped_hash.to_json
      ).body
    ap result
    
    result
  end
  
  def update(update_hash)
    puts "UPDATE ACTIVITY"
    ap update_hash
    activity = ActivityModel.get_model(current_user.login, update_hash['id'])
    ap activity
    
    #calling clone on the following line is EXTREMELY important - update_hash is passed by reference and is what is going to be committed to the DB
    mapped_hash = ActivityMapper.map_data_from_client(update_hash.clone)
    
    mapped_hash['type'] = activity['type']
    mapped_hash['cssi_fromrhosync'] = 'true'
    
    ap mapped_hash
    
    result = RestClient.post("#{@activity_url}/update", 
        :token => @token, 
        :attributes => mapped_hash.to_json
      ).body
    ap result
  end
 
  def delete(object_id)
    
  end
 
  def logoff
    
  end
end