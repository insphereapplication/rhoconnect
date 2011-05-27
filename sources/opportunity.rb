require 'helpers/crypto'

class Opportunity < SourceAdapter
  
  on_api_push do |user_id|
    ExceptionUtil.rescue_and_reraise do
       ExceptionUtil.context(:user_id => user_id )
       PingJob.perform(
         'user_id' => user_id,
         'message' => 'You have new Opportunities',
         'vibrate' => '500',
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
    ExceptionUtil.rescue_and_reraise do
      ExceptionUtil.context(:current_user => current_user.login )
      unless Store.get_value(@initialized_key) == 'true'   
        InsiteLogger.info "QUERY FOR OPPORTUNITIES"
        
        res = RestClient.post(@opportunity_url,
          {:username => @username, 
            :password => @password},
            :content_type => :json
        )
        
        @result = Mapper.map_source_data(res, 'Opportunity')
        
        ExceptionUtil.context(:result => @result)
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
    # TODO: Create a new record in your backend data source
    # If your rhodes rhom object contains image/binary data 
    # (has the image_uri attribute), then a blob will be provided
    raise "Please provide some code to create a single record in the backend data source using the create_hash"
  end
 
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "UPDATE OPPORTUNITY"
      
      # mark this update so the plugin won't unnecessarily push it back
      update_hash['cssi_fromrhosync'] = 'true'
      
      ExceptionUtil.context(:current_user => current_user.inspect, :update_hash => update_hash)
      InsiteLogger.info update_hash
      
      # check for conflicts between the client's requested update and updates that occurred elsewhere
      ConflictManagementUtil.manage_opportunity_conflicts(update_hash, current_user)
      
      # unless conflict management completely rejected the update
      unless update_hash.length == 0
        mapped_hash = OpportunityMapper.map_data_from_client(update_hash.clone)
        
        # update CRM by calling update in Proxy
        result = RestClient.post("#{@opportunity_url}/update", 
            {:username => @username, 
            :password => @password,
            :attributes => mapped_hash.to_json}
          ).body
      
        #persist the updated data in redis
        UpdateUtil.push_objects(@source, update_hash)
        
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