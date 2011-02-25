require 'ap'

class Contact < SourceAdapter
  def initialize(source,credential)
    @contact_url = "http://localhost:5000/contact"
    super(source,credential)
  end
 
  def login
    @token = Store.get_value("username:#{current_user.login}:token")
  end
 
  def query(params=nil)
    parsed_values = JSON.parse(RestClient.post(@contact_url,
        {:token => @token}, 
        :content_type => :json
      )
    )
    ap parsed_values
    @result = parsed_values.reduce({}){|sum, value| sum[value['contactid']] = value; sum }
  end
 
  def sync
    super
  end
 
  def create(create_hash,blob=nil)
    # TODO: Create a new record in your backend data source
    # If your rhodes rhom object contains image/binary data 
    # (has the image_uri attribute), then a blob will be provided
    raise "Please provide some code to create a single record in the backend data source using the create_hash"
  end
 
  def update(attributes)
    puts "^"*80
    ap attributes
    result = JSON.parse(RestClient.post("#{@contact_url}/update", 
      :token => @token, 
      :attributes => attributes.to_json
    ).body)
    puts result
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