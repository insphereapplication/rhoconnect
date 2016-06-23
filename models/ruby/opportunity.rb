class Opportunity < Rhoconnect::Model::Base
  
  # proxy util mixin
  include ProxyUtil
  include ReplaceTempID
  
  
  def self.push_notification(user_id, objects)
      ExceptionUtil.rescue_and_reraise do
         ExceptionUtil.context(:user_id => user_id )
         begin
          lob = objects.fetch(objects.keys[0])['cssi_lineofbusiness']      
          contact_id = objects.fetch(objects.keys[0])['contact_id']
          contact = RedisUtil.get_model('Contact', user_id, contact_id)
         rescue RedisUtil::RecordNotFound
          InsiteLogger.info "Can't find contact for Opportunity."
          return {}
         end
         push_message = 'You have a new Opportunities'
         if !lob.blank?
           push_message = "You have a new #{lob} Opportunity"
           if lob == "Small Biz" && !contact.blank? && !contact['cssi_employer'].blank?
             push_message = "#{push_message} for #{contact['cssi_employer']}"
           elsif !contact.blank? && !contact['firstname'].blank?  && !contact['lastname'].blank?
             push_message = "#{push_message} for #{contact['firstname']} #{contact['lastname']}"
           end
         end
         InsiteLogger.info "about to call PingJOB:  #{push_message}"
         PingJob.perform(
           'user_id' => user_id,
           'message' => push_message,
           'sound' => 'hello.mp3'
         )
       end
    end
  
  
  def initialize(source)
    ExceptionUtil.rescue_and_reraise do
      @opportunity_url = "#{CONFIG[:crm_path]}opportunity"
      @proxy_update_url = "#{@opportunity_url}/update"
      @proxy_create_url = "#{@opportunity_url}/create"
      super(source)
    end
  end
 
  def login    
    ExceptionUtil.rescue_and_reraise do
      UserUtil.enable_if_disabled(current_user.login)
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
	  puts "Query???? #{Store.get_value(@initialized_key)}"
      unless Store.get_value(@initialized_key) == 'true'   
        InsiteLogger.info "QUERY FOR OPPORTUNITIES FOR #{current_user.login}"
        
        start = Time.now
        res = RestClient.post(@opportunity_url,
          {:username => @username, 
            :password => @password},
            :content_type => :json
        )
        InsiteLogger.info "QUERY OPPORTUNITIES PROXY CALL IN FOR #{current_user.login}: #{Time.now - start} Seconds"
        @result = Mapper.map_source_data(res, 'Opportunity')
        ExceptionUtil.context(:result => @result)
		InsiteLogger.info "QUERY OPPORTUNITY RESULTS FOR #{current_user.login} -- #{@result}"
      end 
    end
  end
 
  def sync
    ExceptionUtil.rescue_and_reraise do
	  puts "sync ???? #{Store.get_value(@initialized_key)}"
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

      create_hash = replace_with_guid(create_hash,"contact_id","Contact")

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