require 'ap'

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
    # ap @result
  end
 
  def sync
    puts "ACTIVITY SYNC"
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhosync::Store interface.
    # By default, super is called below which simply saves @result
    super
  end
 
  def create(create_hash,blob=nil)
    puts "CREATE ACTIVITY"
    ap create_hash
    ap "#{@activity_url}/create"
    ap @token
    mapped_hash = ActivityMapper.map_data_from_client(create_hash)
    ap mapped_hash.to_json
    result = RestClient.post("#{@activity_url}/create", 
        :token => @token, 
        :attributes => mapped_hash.to_json
      ).body
    ap result
    result
  end
 
  def update(update_hash)
    puts "UPDATE ACTIVITY"
    ap update_hash
    mapped_hash = ActivityMapper.map_data_from_client(update_hash)
    ap mapped_hash
    result = JSON.parse(RestClient.post("#{@activity_url}/update", 
        :token => @token, 
        :attributes => mapped_hash.to_json
      ).body)
    ap result
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