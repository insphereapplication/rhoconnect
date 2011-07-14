class Opportunity < SourceAdapter
  
  # proxy util mixin
  include ProxyUtil
  
  on_api_push do |user_id|
    ExceptionUtil.rescue_and_reraise do
       ExceptionUtil.context(:user_id => user_id )
       PingJob.perform(
         'user_id' => user_id,
         'message' => 'You have new Opportunities',
         'sound' => 'hello.mp3'
       )
     end
  end
  
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @opportunity_url = "#{CONFIG[:crm_path]}opportunity"
      @proxy_update_url = "#{@opportunity_url}/update"
      @proxy_create_url = "#{@opportunity_url}/create"
      super(source,credential)
    end
  end
 
  def login    
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:opportunity:initialized"
      @user_id_key = "username:#{current_user.login.downcase}:crm_user_id"
    end
  end
 
  def query(params=nil)    
    ExceptionUtil.rescue_and_reraise do
      ExceptionUtil.context(:current_user => current_user.login )
      unless Store.get_value(@initialized_key) == 'true'   
        InsiteLogger.info "QUERY FOR OPPORTUNITIES FOR #{current_user.login}"
        
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
      ExceptionUtil.context(:current_user => current_user.login, :create_hash => create_hash)     
       
      #include user_id context needed by mapper on create
      result = proxy_create(create_hash,{:user_id => Store.get_value(@user_id_key)})    
      InsiteLogger.info result
      result
    end    
  end
 
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "UPDATE OPPORTUNITY"
      
      ExceptionUtil.context(:current_user => current_user.inspect, :update_hash => update_hash)
      InsiteLogger.info update_hash
      
      # check for conflicts between the client's requested update and updates that occurred elsewhere
      update_hash = ConflictManagementUtil.manage_opportunity_conflicts(update_hash, current_user)
      
      # unless conflict management completely rejected the update
      unless update_hash.length <= 1
        
        # update CRM by calling update in Proxy
        start = Time.now
        result = proxy_update(update_hash)
        InsiteLogger.info "OPPORTUNITY PROXY UPDATE IN : #{Time.now - start} Seconds"

        ExceptionUtil.context(:result => result)
        InsiteLogger.info result

      end
    end
  end
  
  def delete(object_id)
    
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end
end