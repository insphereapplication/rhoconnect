class Policy < Rhoconnect::Model::Base
  def initialize(source)
    ExceptionUtil.rescue_and_reraise do
      @policy_url = "#{CONFIG[:crm_path]}policy"
      super(source)
    end
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      UserUtil.enable_if_disabled(current_user.login)
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:policy:initialized"
    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "QUERY FOR POLICIES FOR #{current_user.login}"
      ExceptionUtil.context(:current_user => current_user.login)
	  start = Time.now
      res = RestClient.post(@policy_url, {:username => @username,
                                          :password => @password},
                                          :content_type => :json)
                                          
	  InsiteLogger.info "QUERY POLICIES PROXY CALL IN FOR #{current_user.login}: #{Time.now - start} Seconds"
      @result = Mapper.map_source_data(res, 'Policy')
      
      ExceptionUtil.context(:result => @result)
	  InsiteLogger.info "QUERY POLICIES RESULTS FOR #{current_user.login} -- #{@result}"
      
      # Query for contacts as well to ensure new policies also have their associated contacts (these are not guaranteed to be pushed)
      InsiteLogger.info "QUERYING FOR CONTACTS FOR #{current_user.login} AS PART OF POLICY QUERY"
	  start = Time.now
      contact_query_result = RestClient.post(
        "#{CONFIG[:crm_path]}contact",
        {
          :username => @username, 
          :password => @password
        },
        :content_type => :json
      )
	  InsiteLogger.info "QUERYING FOR CONTACTS FOR #{current_user.login} AS PART OF POLICY QUERY PROXY CALL IN FOR #{current_user.login}: #{Time.now - start} Seconds"
      # Commit the results of the contact query to redis
      contacts = Mapper.map_source_data(contact_query_result, 'Contact')
      contact_source = Source.load('Contact',{:app_id=>APP_NAME,:user_id=>current_user.login})
      UpdateUtil.push_objects(contact_source, contacts)
    end
  end
 
  def sync
    ExceptionUtil.rescue_and_reraise do
      super
    end
  end
 
  def create(create_hash,blob=nil)
    # TODO: Create a new record in your backend data source
    # If your rhodes rhom object contains image/binary data 
    # (has the image_uri attribute), then a blob will be provided
    raise "Please provide some code to create a single record in the backend data source using the create_hash"
  end
 
  def update(update_hash)
    # TODO: Update an existing record in your backend data source
    raise "Please provide some code to update a single record in the backend data source using the update_hash"
  end
 
  def delete(delete_hash)
    # TODO: write some code here if applicable
    # be sure to have a hash key and value for "object"
    # for now, we'll say that its OK to not have a delete operation
    # raise "Please provide some code to delete a single object in the backend application using the object_id"
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end
end