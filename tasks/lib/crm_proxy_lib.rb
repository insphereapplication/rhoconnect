require 'rubygems'
require 'time'
require 'faker'
require 'ap'

class Credential
  attr_accessor :username, :password
  
  def initialize(username, password)
    @username = username
    @password = password
  end
  
  def to_string
    to_hash.to_json
  end
  
  def to_hash
    {:username => @username, :password => @password}
  end
  
  def self.from_string(string)
    parsed_credential_hash = JSON.parse(string)
    Credential.new(parsed_credential_hash["username"], parsed_credential_hash["password"])
  end
  
  def from_hash(hash)
    Credential.new(hash[:username], hash[:password])
  end
end

def login(server, username, password)
  #returns the user's CRM GUID
	RestClient.post("#{server}/session/logon", { :username => username, :password => password }).body.gsub('"', '')
end

def logout(server, token)
  #currently does nothing in the proxy
	RestClient.post("#{server}/session/logout", { :token => token, })
end

def who_am_i(server, credential)
	JSON.parse(RestClient.post("#{server}/user/whoami", credential.to_hash).body)
end

def get_contacts(server, credential)
	get_entities(server,credential.to_hash,'contact')
end

def get_activities(server, credential)
	get_entities(server,credential.to_hash,'activity')
end

def get_opportunities(server, credential)
	get_entities(server,credential.to_hash,'opportunity')
end

def get_entities(server, token, credential)
	JSON.parse(get_entities_json(server, credential.to_hash, model))
end

def get_entities_json(server, credential, model)
	RestClient.post("#{server}/#{model}", credential.to_hash).body
end

def get_log(server, credential, line_count=nil)
	post_attributes = credential.to_hash
	post_attributes[:lines] = line_count if line_count
	
	RestClient.post("#{server}/log", post_attributes).body
end
