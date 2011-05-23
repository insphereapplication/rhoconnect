require 'helpers/crypto'

class Activity < SourceAdapter
  def initialize(source,credential)
    @activity_url = "#{CONFIG[:crm_path]}activity"
    super(source,credential)
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:activity:initialized"
      @user_id_key = "username:#{current_user.login.downcase}:crm_user_id"
    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do      
      unless Store.get_value(@initialized_key) == 'true'
        InsiteLogger.info "ACTIVITY QUERY"
        
        ExceptionUtil.context(:current_user => current_user.login )
        res = RestClient.post(@activity_url,
            {:username => @username, 
             :password => @password}, 
            :content_type => :json
          )
        @result = Mapper.map_source_data(res, 'Activity')
        
        ExceptionUtil.context(:result => res, :mapped_result => @result )
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
      InsiteLogger.info "CREATE ACTIVITY"
      InsiteLogger.info create_hash
      
      #calling clone on the following line is EXTREMELY important - create_hash is passed by reference and is what is going to be committed to the DB
      mapped_hash = ActivityMapper.map_data_from_client(create_hash.clone)
    
      ExceptionUtil.context(:current_user => current_user.login, :mapped_activity_hash => mapped_hash )
      
      # TODO: why isn't this rule in the mapper?
      if mapped_hash['type'].downcase == 'appointment'
        mapped_hash['organizer'] = [{:type => 'systemuser', :id => Store.get_value(@user_id_key)}]
      else #phone call
        mapped_hash['from'] = [{:type => 'systemuser', :id => Store.get_value(@user_id_key)}]
      end
    
      mapped_hash['cssi_fromrhosync'] = 'true'
      ExceptionUtil.context(:current_user => current_user.login, :mapped_activity_hash => mapped_hash )
      
      InsiteLogger.info mapped_hash
      result = RestClient.post("#{@activity_url}/create", 
          {:username => @username, 
          :password => @password,
          :attributes => mapped_hash.to_json}
        ).body
      InsiteLogger.info "Activity Create Result: #{result}"
  
      result
    end
  end
  
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "UPDATE ACTIVITY"
      InsiteLogger.info update_hash
      activity = RedisUtil.get_model('Activity', current_user.login, update_hash['id'])
      InsiteLogger.info activity
    
      #calling clone on the following line is EXTREMELY important - update_hash is passed by reference and is what is going to be committed to the DB
      mapped_hash = ActivityMapper.map_data_from_client(update_hash.clone)
    
      mapped_hash['type'] = activity['type']
      mapped_hash['cssi_fromrhosync'] = 'true'
    
      InsiteLogger.info mapped_hash
      ExceptionUtil.context(:current_user => current_user.login, :mapped_activity_hash => mapped_hash )
      
      result = RestClient.post("#{@activity_url}/update", 
        {:username => @username, 
        :password => @password,
        :attributes => mapped_hash.to_json}
        ).body
      
      UpdateUtil.push_objects(@source, update_hash)
      
      InsiteLogger.info result
    end
  end
 
  def delete(object_id)
    
  end
 
  def logoff
    
  end
end