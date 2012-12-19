

require 'rest-client'
require 'ap'
require 'json'
require 'yaml'
require "#{File.expand_path(File.dirname(__FILE__))}/session_stats"

class RhoconnectSession 
  attr_accessor :client_id
  attr_accessor :base_url
  attr_accessor :login
  DATA_SIZE = 2000
  
  def self.load_or_create(base_url, login, password, force_reload=false)
    if File.exist?(serialized_filename(login)) && !force_reload
      puts "Loading persisted session from #{serialized_filename(login)}"
      load(login)
    else
      #puts "Creating new session for #{login}/#{password}..."
      session = new(base_url, login, password)
      puts "Session created, persisting..."
      session.persist_local
      session
    end
  end
  
  def self.serialized_filename(login)
    File.expand_path(".#{login}_session")
  end
  
  def self.serialized_results_filename()
    File.expand_path("final_results")
  end
  
  def self.combine_results
    @request_stats = SessionStats.new
  end
  
  def self.filename(name)
    File.expand_path(name)
  end
  
  def self.load(login)
    YAML::load(File.read(serialized_filename(login))) 
  end
  
  
  def loadguid(type)
    File.read(RhoconnectSession.filename(".#{@login}_#{type}")) 
  end
  
  def self.clear_local_serialized
    `rm -f .*_session`
  end
  
  def persist_local
    File.open(RhoconnectSession.serialized_filename(@login), 'w+') {|f| f.write(YAML::dump(self)) }
  end
  
  def persist_local_results
    File.open(RhoconnectSession.serialized_results_filename(), 'w+') {|f| f.write(YAML::dump(self)) }
  end
  
  def persist_local_contact(contact_id)
    File.open(RhoconnectSession.filename(".#{@login}_contact"), 'w+') {|f| f.write(contact_id) }
  end
  
  def persist_local_opportunity(opportunity_id)
    File.open(RhoconnectSession.filename(".#{@login}_opportunity"), 'w+') {|f| f.write(opportunity_id)}
  end
  
  def initialize()
     @request_stats = SessionStats.new
  end  
  
  def initialize(base_url, login, password)
    @base_url = base_url
    @request_stats = SessionStats.new
    @login = login
    puts "Logging into #{base_url}/clientlogin..."
    res = RestClient.post "#{base_url}/clientlogin", {:login => login, :password => password}, :content_type => :json
    res.cookies['rhoconnect_session'] = CGI.escape(res.cookies['rhoconnect_session'])  
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
    {'client_id' => client_id, 'p_size' => DATA_SIZE, :version => 3}
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
    #puts "Calling get for #{base_url}?#{url_args(args_hash)}"
    #puts "Headers:"
    #ap headers
    start = Time.now
    res = RestClient.get "#{base_url}?#{url_args(args_hash)}", headers
    @request_stats.add({:action => "get", :time => Time.now - start, :args => args_hash})
    res
  end
  
  def post(args_hash)
    #puts "Calling post for #{base_url}, with body:"
    #ap post_args(args_hash)
    #puts "Headers:"
    #ap post_headers
    start = Time.now
    res = RestClient.post(base_url, post_args(args_hash), post_headers)
    puts "res #{res}"
    @request_stats.add({:action => "post", :time => Time.now - start, :args => args_hash})
    res
  end
  
  def start_test
    @request_stats.reset
    @request_stats.start_time = Time.now
  end
  
  def start_time
    @request_stats.start_time
  end
  
  def end_test
    @request_stats.end_time = Time.now
  end
  
  def end_time
    @request_stats.end_time
  end  
  
  def show_stats
    @request_stats.show
  end
  
  
  def get_stats
     @request_stats.get_stats
  end
  
  def post_headers
    @headers.merge({:content_type => :json})
  end
  
  def create(model, create_hash)
    raise "No session established" unless session_established
    # first post the create
    puts "#{Process.pid} Creating new #{model} for user #{@login}..."
    temp = post({:source_name => model, :create => create_hash})
    puts "temp #{temp}"
    #puts "Getting #{model} links hash..."
    # next get the links hash from a query call -- the links has the new guid from the last create action
    res = get({'source_name' => model})
    
    # get the token for acking
    last_result = JSON.parse(res)
    ap last_result
    ack_token = last_result[1]['token']
    
    puts "ack_token #{ack_token}"
    
    #puts "11111 #{last_result[1]}"
    
    #raise "Create error raised: #{last_result[5]['create-error'].map{|k,v| v['message'] if k='message'}.first}" if last_result[5]['create-error']
    raise "No ack token given after #{model} create for #{login}" unless ack_token
    #raise "No links given after #{model} create for #{login}" unless last_result[5]['links']
    
    puts "Here #{last_result}"
       puts "links: #{last_result[5]['links'].values.first['l']}"
       model_id = last_result[5]['links'].values.first['l']
       puts "model id #{model_id}"
    puts "Links:"
       puts "links #{last_result[5]['links']}"
    
    #puts "New #{model} id: #{model_id}"

    puts "acking the create..."
    get({'source_name' => model, 'token' => ack_token})
    puts "acked, done"
     model_id
  end
  
  def update(model, update_hash)
    puts "#{Process.pid} Updating #{model} for user #{@login}..."
   post({:source_name => model, :update => update_hash})
    res = get({:source_name => model})
    # get the token for acking
    last_result = JSON.parse(res)
    #ap last_result
    #ack_token = last_result[1]['token']
    #raise "No ack token given after #{model} update for #{login}" if ack_token.nil? or ack_token.empty?
    
    #puts "acking the update..."
    #get({:source_name => model, :token => ack_token})
    #puts "acked, done"
    #puts "Updated #{model}"
  end
  
  def query_new(model)
    raise "No session established" unless session_established
    puts "#{Process.pid} Querying #{model} for user #{@login}..."
    raw = get({:source_name => model})
    result = JSON.parse(raw)
    #puts "#{model} found #{result}"
    new_records = result[5]['insert']
    #puts "Parsed query result, building hash..."
    if new_records.nil?
       puts "No #{model}(s) returned from query"
      return
    end
    ack_token = result[1]['token']
    raise "No ack token given after #{model} query with new records for #{login}" if ack_token.nil? or ack_token.empty?
    #puts "Acking query with new records"
    get({:source_name => model, :token => ack_token})
    #puts "Done query"
    new_records
  end
  
  def query_all(model)
    raise "No session established" unless session_established
    puts "#{Process.pid} Querying #{model} for user #{@login}..."
    raw = get({:source_name => model})
    result = JSON.parse(raw)
    #puts "#{model} found #{result}"
    new_records = result[5]['insert']
    #puts "Parsed query result, building hash..."
    #if new_records.nil?
    #    puts "No #{model}(s) returned from query"
    #return
    # end
    # ack_token = result[1]['token']
    #     raise "No ack token given after #{model} query with new records for #{login}" if ack_token.nil? or ack_token.empty?
    #     puts "Acking query with new records"
    #     get({:source_name => model, :token => ack_token})
    puts "Done query"
    result
  end
  
  def session_established
    @client_id && @headers && @headers[:cookies] && @headers[:cookies]['rhoconnect_session']
  end
end