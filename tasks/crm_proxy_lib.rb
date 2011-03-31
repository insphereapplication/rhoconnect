require 'rubygems'
require 'rest_client'
require 'time'
require 'faker'
require 'ap'

def get_token(server, username, password)
	RestClient.post("#{server}/session/logon", { :username => username, :password => password }).body.gsub('"', '')
end

def logout(server, token)
	RestClient.post("#{server}/session/logout", { :token => token, })
end

def who_am_i(server, token)
	JSON.parse(RestClient.post("#{server}/user/whoami", { :token => token, }).body)
end

def get_contacts(server, token)
	get_entities(server,token,'contact')
end

def get_activities(server, token)
	get_entities(server,token,'activity')
end

def get_opportunities(server, token)
	get_entities(server,token,'opportunity')
end

def get_entities(server, token, model)
	JSON.parse(get_entities_json(server, token, model))
end

def get_entities_json(server, token, model)
	RestClient.post("#{server}/#{model}", { :token => token, }).body
end

def get_log(server, token, line_count=nil)
	post_attributes = { :token => token }
	post_attributes[:lines] = line_count if line_count
	
	RestClient.post("#{server}/log", post_attributes).body
end
