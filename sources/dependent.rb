class Dependent < SourceAdapter
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @dependent_url = "#{CONFIG[:crm_path]}dependents"
      super(source,credential)
    end
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:dependent:initialized"
    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do
      #unless Store.get_value(@initialized_key) == 'true'
        InsiteLogger.info "QUERY FOR DEPENDENTS for #{current_user.login.downcase}"
        ExceptionUtil.context(:current_user => current_user.login)
        res = RestClient.post(@dependent_url, {:username => @username,
                                            :password => @password},
                                            :content_type => :json)
                                            
        @result = Mapper.map_source_data(res, 'Dependent')
        
        ExceptionUtil.context(:result => @result)
        InsiteLogger.info @result
      #end
    end
  end
 
  def sync
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'  
        super
        Store.put_value(@initialized_key, 'true')
      end
    end
    super
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