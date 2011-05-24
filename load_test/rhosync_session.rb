require 'rest-client'
require 'ap'
require 'json'
require 'yaml'
require 'session_stats'

class RhosyncSession 
  attr_accessor :client_id
  attr_accessor :base_url
  SERIALIZED_FILENAME = ".session_yml"
  DATA_SIZE = 2000
  
  def self.load_or_create(*args)
    puts 
    if File.exist?(File.expand_path(SERIALIZED_FILENAME))
      puts "Loading persisted session from #{File.expand_path(SERIALIZED_FILENAME)}"
      load
    else
      session = new(*args)
      session.persist_local
      session
    end
  end
  
  def self.load
    YAML::load(File.read(SERIALIZED_FILENAME)) 
  end
  
  def self.clear_local_serialized
    File.delete(SERIALIZED_FILENAME) if File.exist?(SERIALIZED_FILENAME)
  end
  
  def persist_local
    File.open(SERIALIZED_FILENAME, 'w+') {|f| f.write(YAML::dump(self)) }
  end
  
  def initialize(base_url, login, password)
    @base_url = base_url
    @request_stats = SessionStats.new
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
    hsh.merge(base_post_args).to_json
  end
  
  def get(args_hash={})
    RestClient.get "#{base_url}?#{url_args(args_hash)}", headers
  end
  
  def post(args_hash)
    start = Time.now
    res = RestClient.post(base_url, post_args(args_hash), post_headers)
    @request_stats.add({:action => "post", :time => Time.now - start})
    res
  end
  
  def start_test
    @request_stats.reset
    @request_stats.start_time = Time.now
  end
  
  def end_test
    @request_stats.end_time = Time.now
  end
  
  def show_stats
    @request_stats.show
  end
  
  def post_headers
    @headers.merge({:content_type => :json})
  end
  
  def create(model, create_hash)
    raise "No session established" unless session_established
    # first post the create
    puts "Creating new #{model}..."
    post({:source_name => model}.merge({:create => create_hash}))

    # next get the links hash from a query call -- the links has the new guid from the last create action
    res = get({'source_name' => model})

    # get the token for acking
    last_result = JSON.parse(res)
    ack_token = last_result[1]['token']
    model_id = last_result[5]['links'].values.first['l']
    puts "New #{model} id: #{model_id}"

    puts "acking the create..."
    get({'source_name' => model, 'token' => ack_token})
    puts "acked, done"
    model_id
  end
  
  def update(model, update_hash)
    puts "Updating #{model}..."
    post({:source_name => model}.merge({:update => update_hash}))
    puts "Updated #{model}"
  end
  
  def query(model)
    raise "No session established" unless session_established
    puts "Querying #{model}..."
    raw = get({'source_name' => model} )
    result = JSON.parse(raw)
    puts "Parsed query result, building hash..."
    opps = result.select{|hsh| hsh.keys.include?('insert') }.first['insert'].values
    puts "Done query"
    opps
  end
  
  def session_established
    @client_id && @headers && @headers[:cookies] && @headers[:cookies]['rhosync_session']
  end
end