class Activity < SourceAdapter
  def initialize(source,credential)
    @activity_url = "#{CONFIG[:crm_path]}activity"
    super(source,credential)
  end
 
  def login
    @token = Store.get_value("username:#{current_user.login}:token")
  end
 
  def query(params=nil)
    res = RestClient.post(@activity_url,
        {:token => @token}, 
        :content_type => :json
      )
  
    @result = ActivityMapper.map_json(res)
  end
 
  def sync
    puts "NOTE SYNC"
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhosync::Store interface.
    # By default, super is called below which simply saves @result
    super
  end
 
  def create(create_hash,blob=nil)
    # TODO: Create a new record in your backend data source
    # If your rhodes rhom object contains image/binary data 
    # (has the image_uri attribute), then a blob will be provided
    raise "Please provide some code to create a single record in the backend data source using the create_hash"
  end
 
  def update(update_hash)
    result = JSON.parse(RestClient.post("#{@activity_url}/update", 
        :token => @token, 
        :attributes => attributes.to_json
      ).body)
  end
 
  def delete(object_id)
    # TODO: write some code here if applicable
    # be sure to have a hash key and value for "object"
    # for now, we'll say that its OK to not have a delete operation
    # raise "Please provide some code to delete a single object in the backend application using the object_id"
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end
end