class Policy < SourceAdapter
  include ProxyUtil
   
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @policy_url = "#{CONFIG[:crm_path]}policy"
      @proxy_create_url = "#{@policy_url}/create"
      super(source,credential)
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
      res = RestClient.post(@policy_url, {:username => @username,
                                          :password => @password},
                                          :content_type => :json)
                                          
      @result = Mapper.map_source_data(res, 'Policy')
      
      ExceptionUtil.context(:result => @result)
      InsiteLogger.info @result
      
      # Query for contacts as well to ensure new policies also have their associated contacts (these are not guaranteed to be pushed)
      InsiteLogger.info "QUERYING FOR CONTACTS FOR #{current_user.login} AS PART OF POLICY QUERY"
      contact_query_result = RestClient.post(
        "#{CONFIG[:crm_path]}contact",
        {
          :username => @username, 
          :password => @password
        },
        :content_type => :json
      )
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
    #  Dwayne.Smith -  Create the method so that data can be populate through load test scripts
    #raise "Please provide some code to create a single record in the backend data source using the create_hash"
      ExceptionUtil.rescue_and_reraise do
        InsiteLogger.info "CREATE Policy"
        ExceptionUtil.context(:current_user => current_user.login, :create_hash => create_hash)

          result = proxy_create(create_hash,{:user_id => Store.get_value(@user_id_key)})     

        InsiteLogger.info result
        result
      end
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