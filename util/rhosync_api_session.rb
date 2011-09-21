app_path = File.expand_path(File.join(File.dirname(__FILE__))) 
require "#{app_path}/../util/config_file"
require "#{app_path}/../helpers/crypto"

require 'rest-client'
require 'ap'
require 'json'
require 'yaml'

class RhosyncApiSession
  
  def initialize(host, password)
    @server = host
    @password = password
    login
  end
  
  def push_deletes(source_id, user_id, object_ids)
    params_hash = {
      :api_token => @token,
      :user_id => user_id,
      :source_id => source_id,
      :objects => object_ids
    }
    RestClient.post(
      "#{@server}api/push_deletes",
      params_hash.to_json,
      :content_type => :json
    )
  end
    
  def get_user_password(user)    
    encrypted_password = get_db_doc("username:#{user}:password", 'string')
    Crypto.decrypt(encrypted_password)
  end  
  
  def get_db_doc(doc, type=nil)
    
    params_hash = { :api_token => @token, :doc => doc }
    params_hash[:data_type] = 'string' if !type.nil? && type=='string'
    
    doc_data = RestClient.post("#{@server}api/get_db_doc", 
      params_hash.to_json, 
      :content_type => :json
    ).body
    
    if type.nil?
      JSON.parse(doc_data)
    else
      doc_data
    end
  end
  
  def list_source_docs(source_id, user_id)
    docs = RestClient.post("#{@server}api/list_source_docs", 
      { :api_token => @token, 
        :source_id => source_id, 
        :user_id => user_id }.to_json, 
      :content_type => :json
    ).body
    JSON.parse(docs)
  end
  
  def list_sources
    sources = RestClient.post("#{@server}api/list_sources", 
      { 
        :api_token => @token 
      }.to_json, 
      :content_type => :json
    ).body
    sources.gsub(/[\[\]]/, '').gsub('"','').split(",")
  end

  def get_device_params(id)
    device_params = RestClient.post("#{@server}api/get_client_params", 
      { :api_token => @token, 
        :client_id => id }.to_json, 
      :content_type => :json
    ).body
    JSON.parse(device_params)
  end

  def get_user_devices(username)
    clients = RestClient.post("#{@server}api/list_clients", 
      { :api_token => @token, 
        :user_id => username }.to_json, 
     :content_type => :json
    ).body
    clients.gsub(/[\[\]]/, '').gsub('"','').split(",")
  end

  def get_all_users
    users = RestClient.post("#{@server}api/list_users",
      { :api_token => @token }.to_json, 
      :content_type => :json
    ).body
    users.gsub(/[\[\]]/, '').gsub('"','').split(",")
  end
  
  def get_sync_status(user_pattern)
    raw_sync_status = RestClient.post("#{@server}api/get_sync_status", 
      { :api_token => @token, 
        :user_pattern => user_pattern }.to_json, 
      :content_type => :json
    ).body

    sync_status = JSON.parse(raw_sync_status)
    
    # build hash of user -> init flags of the format {'<username>' => ['<source_name1>', '<source_name2>', ...]}
    init_flags = sync_status['matching_init_keys'].reduce({}){|sum,init_key| 
      parsed = init_key.match(/username:([^:]+):([^:]+)/)
      sum[parsed[1]] ||= []
      sum[parsed[1]] << parsed[2]
      sum
    }
    # build hash of user -> (source, refresh_time) values of the format {'<username>' => [{:source => '<source_name1>', :time => '<refresh_time>'}, {:source => '<source_name2>', :time => ...}]}
    refresh_times = sync_status['matching_refresh_time_keys'].reduce({}){|sum,(key,time)|
      parsed = key.match(/read_state:application:([^:]+):([^:]+)/)
      sum[parsed[1]] ||= []
      sum[parsed[1]] << {:source => parsed[2], :time => Time.at(time.to_i)}
      sum
    }
    {:initialized_sources => init_flags, :refresh_times => refresh_times}
  end
  
  def reset_sync_status(username)
   res = JSON.parse(RestClient.post(
      "#{@server}api/reset_sync_status", 
      { 
        :api_token => @token, 
        :user_pattern => username
      }.to_json, 
      :content_type => :json
    ).body)
  end

  def get_dead_locks
    res = RestClient.post(
      "#{@server}api/get_dead_locks", 
      { 
        :api_token => @token
      }.to_json, 
      :content_type => :json
    ).body
    dead_locks = JSON.parse(res)
    # return a hash mapping the lock keys to the time at which they expired (i.e. {'lock:user:model:md' => Apr 25 2011 15:54 -0500})
    dead_locks.reduce({}){|sum,(key,value)| sum[key] = Time.at(value.to_i); sum }
  end
  
  def release_lock(lock)
    res = RestClient.post(
      "#{@server}api/release_lock", 
      { 
        :api_token => @token,
        :lock => lock
      }.to_json, 
      :content_type => :json
    ).body
  end

  def login()
    res = RestClient.post("#{@server}login", { :login => 'rhoadmin', :password => @password }.to_json, :content_type => :json)
  
    #The following fix is needed when using rest-client 1.6.1;
    #The make_headers function (lib/restclient/request.rb, line 86) uses CGI::unescape, but we want the cookies
    #submitted to RhoSync to remain escaped. The following code simply replaces all '%' characters with their
    #URL-encoded value of '%25' to prevent escaped characters in the given cookie from being unescaped by
    #rest-client. For example, a given cookie of "1234%3D%0A5" would have been unescaped and sent back to
    #RhoSync as "12345=\n5", but RhoSync expects the cookie to be in its original escaped format.
    cookies = res.cookies.inject({}){ |h,(key,value)| 
      h[key] = value.gsub('%', '%25')
      h
    }
    @token = RestClient.post("#{@server}api/get_api_token",'',{ :cookies => cookies, })
  end

end