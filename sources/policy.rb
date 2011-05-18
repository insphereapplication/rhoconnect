class Policy < SourceAdapter
  def initialize(source,credential)
    ap "Policy.initialize"
    ExceptionUtil.rescue_and_reraise do
      @policy_url = "#{CONFIG[:crm_path]}policy"
      ap "*** Policy URL = #{@policy_url} ***"
      super(source,credential)
    end
  end
 
  def login
    ap "Policy.login"
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:policy:initialized"
    end
  end
 
  def query(params=nil)
    ap "Policy.query"
    ExceptionUtil.rescue_and_reraise do
      # unless Store.get_value(@initialized_key) == 'true'
        InsiteLogger.info "QUERY FOR POLICIES for #{current_user.login.downcase}"
        ap "*** Policy URL = #{@policy_url} ***"
        ExceptionUtil.context(:current_user => current_user.login)
        res = RestClient.post(@policy_url,
        {:username => @username,
         :password => @password},
         :content_type => :json)
         
        ExceptionUtil.context(:result => @result)
      # else
      #   ap "*** initialized_key == #{@initialized_key} ***"
      # end
    end
  end
 
  def sync
    ap "Policy.sync"
    ExceptionUtil.rescue_and_reraise do
      unless Store.get_value(@initialized_key) == 'true'  
        super
        Store.put_value(@initialized_key, 'true')
      else
        ap "*** initialized_ley == #{@initialized_key} ***"
      end
    end
  end
 
  def create(create_hash,blob=nil)
    ap "Policy.create"
    # TODO: Create a new record in your backend data source
    # If your rhodes rhom object contains image/binary data 
    # (has the image_uri attribute), then a blob will be provided
    raise "Please provide some code to create a single record in the backend data source using the create_hash"
  end
 
  def update(update_hash)
    ap "Policy.update"
    # TODO: Update an existing record in your backend data source
    raise "Please provide some code to update a single record in the backend data source using the update_hash"
  end
 
  def delete(delete_hash)
    ap "Policy.delete"
    # TODO: write some code here if applicable
    # be sure to have a hash key and value for "object"
    # for now, we'll say that its OK to not have a delete operation
    # raise "Please provide some code to delete a single object in the backend application using the object_id"
  end
 
  def logoff
    ap "Policy.logoff"
    # TODO: Logout from the data source if necessary
  end
end