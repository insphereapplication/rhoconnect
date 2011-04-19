
class Activity < SourceAdapter
  def initialize(source,credential)
    @activity_url = "#{CONFIG[:crm_path]}activity"
    super(source,credential)
  end
 
  def login
    Exceptional.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      @password = Store.get_value("username:#{current_user.login.downcase}:password")
      @initialized_key = "username:#{current_user.login.downcase}:activity:initialized"
      @user_id_key = "username:#{current_user.login.downcase}:crm_user_id"
    end
  end
 
  def query(params=nil)
    Exceptional.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'
        ap "ACTIVITY QUERY"
        
        Exceptional.context(:current_user => current_user.login )
        res = RestClient.post(@activity_url,
            {:username => @username, 
             :password => @password}, 
            :content_type => :json
          )
        @result = Mapper.map_source_data(res, 'Activity')
        
        Exceptional.context(:result => res, :mapped_result => @result )
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
      puts "CREATE ACTIVITY"
      ap create_hash
      ap "#{@activity_url}/create"
      ap @token
      
      #calling clone on the following line is EXTREMELY important - create_hash is passed by reference and is what is going to be committed to the DB
      mapped_hash = ActivityMapper.map_data_from_client(create_hash.clone)
    
      Exceptional.context(:current_user => current_user.login, :mapped_activity_hash => mapped_hash )
      
      if mapped_hash['type'].downcase == 'appointment'
        mapped_hash['organizer'] = [{:type => 'systemuser', :id => Store.get_value(@user_id_key)}]
      else #phone call
        mapped_hash['from'] = [{:type => 'systemuser', :id => Store.get_value(@user_id_key)}]
      end
    
      mapped_hash['cssi_fromrhosync'] = 'true'
      Exceptional.context(:current_user => current_user.login, :mapped_activity_hash => mapped_hash )
      
      ap mapped_hash
      result = RestClient.post("#{@activity_url}/create", 
          {:username => @username, 
          :password => @password,
          :attributes => mapped_hash.to_json}
        ).body
      ap result
    
      result
    end
  end
  
  def update(update_hash)
    Exceptional.rescue_and_reraise do
      puts "UPDATE ACTIVITY"
      ap update_hash
      activity = ActivityModel.get_model(current_user.login, update_hash['id'])
      ap activity
    
      #calling clone on the following line is EXTREMELY important - update_hash is passed by reference and is what is going to be committed to the DB
      mapped_hash = ActivityMapper.map_data_from_client(update_hash.clone)
    
      mapped_hash['type'] = activity['type']
      mapped_hash['cssi_fromrhosync'] = 'true'
    
      ap mapped_hash
      Exceptional.context(:current_user => current_user.login, :mapped_activity_hash => mapped_hash )
      
      result = RestClient.post("#{@activity_url}/update", 
        {:username => @username, 
        :password => @password,
        :attributes => mapped_hash.to_json}
        ).body
      ap result
    end
  end
 
  def delete(object_id)
    
  end
 
  def logoff
    
  end
end