require 'ap'

class Activity < SourceAdapter
  def initialize(source,credential)
    @activity_url = "#{CONFIG[:crm_path]}activity"
    super(source,credential)
  end
 
  def login
    @token = Store.get_value("username:#{current_user.login}:token")
    @initialized_key = "username:#{current_user.login}:activity:initialized"
  end
 
  def query(params=nil)
    unless Store.get_value(@initialized_key) == 'true'
      res = RestClient.post(@activity_url,
          {:token => @token}, 
          :content_type => :json
        )
      @result = ActivityMapper.map_json(res)
    end
  end
 
  def sync
    unless Store.get_value(@initialized_key) == 'true'  
      super
      Store.put_value(@initialized_key, 'true')
    end
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
    
  end
 
  def logoff
    
  end
end