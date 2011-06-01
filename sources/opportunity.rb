class Opportunity < SourceAdapter
  
  on_api_push do |user_id|
    ExceptionUtil.rescue_and_reraise do
       ExceptionUtil.context(:user_id => user_id )
       PingJob.perform(
         'user_id' => user_id,
         'message' => 'You have new Opportunities',
         'vibrate' => '2000',
         'sound' => 'hello.mp3'
       )
     end
  end
  
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @opportunity_url = "#{CONFIG[:crm_path]}opportunity"
      super(source,credential)
    end
  end
 
  def login    
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:opportunity:initialized"
    end
  end
 
  def query(params=nil)
    InsiteLogger.info "OPPPORTUNITY QUERY FOR #{current_user}"
    InsiteLogger.info @initialized_key
    InsiteLogger.info Store.get_value(@initialized_key)
    
    ExceptionUtil.rescue_and_reraise do
      ExceptionUtil.context(:current_user => current_user.login )
      unless Store.get_value(@initialized_key) == 'true'   
        InsiteLogger.info "QUERY FOR OPPORTUNITIES"
        
        start = Time.now
        res = RestClient.post(@opportunity_url,
          {:username => @username, 
            :password => @password},
            :content_type => :json
        )
        InsiteLogger.info "OPPORTUNITY QUERY PROXY CALL IN : #{Time.now - start} Seconds"
        @result = Mapper.map_source_data(res, 'Opportunity')
        ExceptionUtil.context(:result => @result)
      end 
    end
  end
 
  def sync
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'  
        start = Time.now
        super
        Store.put_value(@initialized_key, 'true')
        InsiteLogger.info "OPPORTUNITY SYNC IN #{Time.now - start} SECONDS" 
      end
    end
  end
 
  def create(create_hash,blob=nil)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "CREATE OPPORTUNITY"
      ExceptionUtil.context(:current_user => current_user.login)      
      mapped_hash = OpportunityMapper.map_data_from_client(create_hash.clone, current_user)
      result = RestClient.post("#{@opportunity_url}/create",
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
      InsiteLogger.info "UPDATE OPPORTUNITY"
      update_hash['cssi_fromrhosync'] = 'true'
      ExceptionUtil.context(:current_user => current_user.inspect, :update_hash => update_hash)
      InsiteLogger.info update_hash

      mapped_hash = OpportunityMapper.map_data_from_client(update_hash.clone, current_user)

      start = Time.now
      result = RestClient.post("#{@opportunity_url}/update", 
          {:username => @username, 
          :password => @password,
          :attributes => mapped_hash.to_json}
        ).body
      InsiteLogger.info "OPPORTUNITY PROXY UPDATE IN : #{Time.now - start} Seconds"
      UpdateUtil.push_objects(@source, update_hash)
        
      ExceptionUtil.context(:result => result)
      InsiteLogger.info result
    end
  end
  
  def delete(object_id)
    
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end
end