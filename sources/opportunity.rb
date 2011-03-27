require 'ap'

class Opportunity < SourceAdapter
  
  on_api_push do |user_id|
     PingJob.perform(
       'user_id' => user_id,
       'message' => 'You have new Opportunities',
       'vibrate' => '2000',
       'sound' => 'hello.mp3'
     )
  end
  
  def initialize(source,credential)
    @opportunity_url = "#{CONFIG[:crm_path]}opportunity"
    super(source,credential)
  end
 
  def login
    @token = Store.get_value("username:#{current_user.login.downcase}:token")
    @initialized_key = "username:#{current_user.login.downcase}:opportunity:initialized"
  end
 
  def query(params=nil)
    unless Store.get_value(@initialized_key) == 'true'   
      ap "QUERY FOR OPPORTUNITIES"
      parsed_values = JSON.parse(RestClient.post(@opportunity_url,
          {:token => @token}, 
          :content_type => :json
        )
      )
      @result = parsed_values.reduce({}){|sum, value| sum[value['opportunityid']] = value; sum }
      ap @result
    end 
  end
 
  def sync
    unless Store.get_value(@initialized_key) == 'true'  
      super
      Store.put_value(@initialized_key, 'true')
    end
  end
 
  def create(create_hash,blob=nil)
    # TODO: Create a new record in your backend data source
    # If your rhodes rhom object contains image/binary data 
    # (has the image_uri attribute), then a blob will be provided
    raise "Please provide some code to create a single record in the backend data source using the create_hash"
  end
 
  def update(update_hash)
    puts "UPDATE OPPORTUNITY"
    update_hash['cssi_fromrhosync'] = 'true'
    ap update_hash
    result = RestClient.post("#{@opportunity_url}/update", 
        :token => @token, 
        :attributes => update_hash.to_json
      ).body
    ap result
  end
 
  def delete(object_id)
    
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end
end