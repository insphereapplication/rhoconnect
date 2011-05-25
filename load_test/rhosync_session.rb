require 'rest-client'
require 'ap'
require 'json'
require 'yaml'
require 'session_stats'

class RhosyncSession 
  attr_accessor :client_id
  attr_accessor :base_url
  attr_accessor :login
  DATA_SIZE = 2000
  
  def self.load_or_create(base_url, login, password, force_reload=false)
    if File.exist?(serialized_filename(login)) && !force_reload
      puts "Loading persisted session from #{serialized_filename(login)}"
      load(login)
    else
      puts "Creating new session for #{login}/#{password}..."
      session = new(base_url, login, password)
      puts "Session created, persisting..."
      session.persist_local
      session
    end
  end
  
  def self.serialized_filename(login)
    File.expand_path(".#{login}.session")
  end
  
  def self.load(login)
    YAML::load(File.read(serialized_filename(login))) 
  end
  
  def self.clear_local_serialized
    `rm -f *_session`
  end
  
  def persist_local
    File.open(RhosyncSession.serialized_filename(@login), 'w+') {|f| f.write(YAML::dump(self)) }
  end
  
  def initialize(base_url, login, password)
    @base_url = base_url
    @request_stats = SessionStats.new
    @login = login
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
    puts "Calling get for #{base_url}?#{url_args(args_hash)}"
    puts "Headers:"
    ap headers
    RestClient.get "#{base_url}?#{url_args(args_hash)}", headers
  end
  
  def post(args_hash)
    puts "Calling post for #{base_url}, with body:"
    ap post_args(args_hash)
    puts "Headers:"
    ap post_headers
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
    puts "Getting #{model} links hash..."
    # next get the links hash from a query call -- the links has the new guid from the last create action
    res = get({'source_name' => model})
    # get the token for acking
    last_result = JSON.parse(res)
    ack_token = last_result[1]['token']
    raise "Create error raised: #{last_result[5]['create-error'].map{|k,v| v['message'] if k='message'}.first}" if last_result[5]['create-error']
    raise "No ack token given after #{model} create for #{login}" unless ack_token
    raise "No links given after #{model} create for #{login}" unless last_result[5]['links']
    
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
    insert_array = result.select{|hsh| hsh.keys.include?('insert') }
    puts "Parsed query result, building hash..."
    unless insert_array.size > 0
      puts "No #{model}(s) returned from query"
      return
    end
    opps = insert_array.first['insert'].values
    puts "Done query"
    opps
  end
  
  def session_established
    @client_id && @headers && @headers[:cookies] && @headers[:cookies]['rhosync_session']
  end
end