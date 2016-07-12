class Activity < Rhoconnect::Model::Base

  # proxy util mixin
  include ProxyUtil
  include ReplaceTempID
  
  def initialize(source)
    @activity_url = "#{CONFIG[:crm_path]}activity"
    @proxy_update_url = "#{@activity_url}/update"
    @proxy_create_url = "#{@activity_url}/create"
    super(source)
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      UserUtil.enable_if_disabled(current_user.login)
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
       
        ExceptionUtil.context(:current_user => current_user.login )
        
        InsiteLogger.info "QUERY FOR ACTIVITIES FOR #{current_user.login}"
        start = Time.now
        res = RestClient.post(@activity_url,
            {:username => @username, 
             :password => @password}, 
            :content_type => :json
          )
        InsiteLogger.info "ACTIVITY PROXY QUERY IN : #{Time.now - start} Seconds"
        @result = Mapper.map_source_data(res, 'Activity')
        


        #activity work around for blank description error on phone
        @result.each do |id, activity|
          activity_type = activity['type']
          activity_description = activity['description']
          if (['Task','Appointment'].include?(activity_type) && activity_description.nil?)
             InsiteLogger.debug "Activity description is nil for user: #{current_user.login} activity: #{id}"
             activity['description'] =  ''
           end
           activity
         end
         InsiteLogger.info @result
         #end of workaround
         
        
        ExceptionUtil.context(:result => res, :mapped_result => @result )
      end
    end
  end
 
  def sync
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'  
        start = Time.now
        super
        Store.put_value(@initialized_key, 'true')
        InsiteLogger.info "ACTIVITY SYNC IN #{Time.now - start} SECONDS" 
      end
    end
  end
 
  def create(create_hash,blob=nil)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "CREATE ACTIVITY"
    
      ExceptionUtil.context(:current_user => current_user.login, :create_hash => create_hash )
            
      start_proxy = Time.now
      create_hash = replace_with_guid(create_hash,"parent_id",create_hash['parent_type'])
      create_hash = replace_with_guid(create_hash,"parent_contact_id","Contact")

      result = proxy_create(create_hash,{:user_id => Store.get_value(@user_id_key)}) # Include user ID context needed by mapper on creates
      InsiteLogger.info "ACTIVITY PROXY CREATE IN : #{Time.now - start_proxy} Seconds"
      InsiteLogger.info "Activity Create Result: #{result}"
      result
    end
  end
  
  def update(update_hash)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "UPDATE ACTIVITY"
      
      # Fetch the activity's type from redis so that the proxy will know which type it's interacting with
      # This has to be done because the differential update sent to the proxy will only include the activity type if it has changed, which should never be the case
      begin
        update_hash = replace_with_guid(create_hash,"id","Activity")
        activity = RedisUtil.get_model('Activity', current_user.login, update_hash['id'])
      rescue RedisUtil::RecordNotFound
        # Activity doesn't exist in redis, stop. Activity will be deleted on client after this sync.
        InsiteLogger.info(:format_and_join => ["Couldn't find existing activity in redis, rejecting update: ", update_hash])
        return
      end
      
      if activity['statecode'] == 'Completed'
        InsiteLogger.info "ACTIVITY STATECODE COMPLETE in Rhosync for #{update_hash['id']} cannot apply changes"
        result = update_hash['id']
        
      else
        update_hash['type'] = activity['type']
        update_hash['parent_type'] = activity['parent_type']  if (!update_hash['parent_id'].blank? && update_hash['parent_type'].blank?)
      
        ExceptionUtil.context(:current_user => current_user.login, :update_hash => update_hash )
      
        start = Time.now
        begin
          result = proxy_update(update_hash)
        rescue Exception => ex
                  
          raise ex unless ex.inspect &&ex.inspect.index("Cannot update Closed or Cancelled Activity")
          #Do nothing if the Activity is already closed.
          InsiteLogger.info "ACTIVITY STATECODE COMPLETE in CRM for #{update_hash['id']} cannot apply changes"
          result = update_hash['id']
        
        end
        InsiteLogger.info "ACTIVITY PROXY UPDATE IN : #{Time.now - start} Seconds"
      end
      
      
      InsiteLogger.info result
    end
  end
 
  def delete(object_id)
    
  end
 
  def logoff
    
  end
end