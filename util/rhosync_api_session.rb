app_path = File.expand_path(File.join(File.dirname(__FILE__))) 
require "#{app_path}/../util/config_file"

require 'rest-client'
require 'ap'
require 'json'
require 'yaml'

class RhosyncApiSession
  
  def initialize(target)    
    load_config_settings(target)            
    login()
    set_token()
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

  def load_config_settings(target)
    @target = target || :onsite_model
    settings = YAML::load_file('settings/settings.yml')
  
    @config = ConfigFile.get_settings_for_environment(settings, @target)
    @app_path = File.expand_path(File.dirname(__FILE__))
    @server = (@config[:syncserver] || "").sub('/application', '')
    @password = (@config[:rhoadmin_password] || "")    
  end

  def login()
    res = RestClient.post("#{@server}login", { :login => 'rhoadmin', :password => @password }.to_json, :content_type => :json)
  
    #The following fix is needed when using rest-client 1.6.1;
    #The make_headers function (lib/restclient/request.rb, line 86) uses CGI::unescape, but we want the cookies
    #submitted to RhoSync to remain escaped. The following code simply replaces all '%' characters with their
    #URL-encoded value of '%25' to prevent escaped characters in the given cookie from being unescaped by
    #rest-client. For example, a given cookie of "1234%3D%0A5" would have been unescaped and sent back to
    #RhoSync as "12345=\n5", but RhoSync expects the cookie to be in its original escaped format.
    @preserved_cookies = res.cookies.inject({}){ |h,(key,value)| 
       h[key] = value.gsub('%', '%25')
       h
     }
  end

  def set_token
    tokenfile = '.rhosync_token'
    begin
      @token = RestClient.post("#{@server}api/get_api_token",'',{ :cookies => @preserved_cookies, })    
      File.open(tokenfile, 'w') {|f| f.write(@token) }
    rescue Exception => e
      puts "!!!! Exception thrown: #{e.inspect}"
    end    
  end

  def get_token
    tokenfile = '.rhosync_token'
    begin
      if File.exists?(tokenfile)
        @token = File.readlines(tokenfile).first.strip
      else
        set_token
      end
    rescue Exception => e
      puts "!!!! Exception thrown: #{e.inspect}"
    end
    @token
  end

end