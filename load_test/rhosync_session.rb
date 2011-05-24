require 'rest-client'
require 'ap'
require 'json'

class RhosyncSession 
  attr_accessor :client_id
  attr_accessor :base_url
  DATA_SIZE = 2000
  
  def initialize(base_url, login, password)
    @base_url = base_url
    puts "Logging into #{base_url}/clientlogin..."
    res = RestClient.post "#{base_url}/clientlogin", {:login => login, :password => password}, :content_type => :json
    res.cookies['rhosync_session'] = CGI.escape(res.cookies['rhosync_session'])  
    puts "Logged in, getting client id..."
    @headers = {}
    @headers[:cookies] = res.cookies
    create = RestClient.get "#{base_url}/clientcreate", headers
    @client_id = JSON.parse(create.body)['client']['client_id']
    puts "Logged in with client id: #{self.client_id}"
  end
  
  def headers
    @headers.clone
  end
  
  def base_url_args
    {'client_id' => client_id, 'p_size' => DATA_SIZE}
  end
  
  def base_post_args
    {'client_id' => client_id, :version => 3}
  end
  
  def url_args(hsh)
    hsh.merge(base_url_args).map { |k,v| "#{k}=#{v}" }.join("&")
  end
  
  def post_args(hsh)
    hsh.merge(base_post_args)
  end
  
  def get(action='', args_hash={})
    RestClient.get "#{base_url}#{action}?#{url_args(args_hash)}", headers
  end
  
  def post_headers
    @headers.merge({:content_type => :json})
  end
  
  def post(args_hash)
    RestClient.post(base_url, post_args(args_hash), post_headers)
  end
  
  def create(model, create_hash)
    raise "No session established" unless session_established
    # first post the create
    post({:source_name => model}.merge(create_hash))
    
    # next get the links hash from a query call -- the links has the new guid from the last create action
    res = get('', {'source_name' => model} )

    # get the token for acking
    last_result = JSON.parse(res)
    # activity_token = last_result[1]['token']
    # ap last_result
    # get the phone call id for the last created phone call 
    ap last_result[5]
    # new_phone_call_id = JSON.parse(session.last_result.body)[5]['links'].values.first['l']
    # 
    # puts "NEW PHONE CALL ID: #{new_phone_call_id}"
    # session.get "ack-cud", config.base_url do
    #   { 'source_name' => 'Activity', 'client_id' => client[1], 'token' => activity_token}
    # end
    # 
    #  puts "Got phone call ID!"
  end
  
  def query(model)
    raise "No session established" unless session_established
    raw = get('', {'source_name' => model} )
    result = JSON.parse(raw)
    result.select{|hsh| hsh.keys.include?('insert') }.first['insert'].values
  end
  
  def session_established
    @client_id && @headers && @headers[:cookies] && @headers[:cookies]['rhosync_session']
  end
end