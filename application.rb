require File.expand_path(File.dirname(__FILE__) + '/boot.rb')
require 'ap'

class Application < Rhosync::Base
  class << self
    def authenticate(username,password,session)
      puts "Authentication requested #{username}:#{password}"
      ap "Logging onto #{CONFIG[:crm_path]}session/logon"
      response = RestClient.post "#{CONFIG[:crm_path]}session/logon", :username => username, :password => password
      ap response.to_s
      if response.code == 200
        Store.put_value("username:#{username.downcase}:token", response.body.strip.gsub(/"/, ''))
        return true
      elsif response.code == 401
        return false
      end   
    end
    
    def initializer(path)
      super
    end
    
    def store_blob(object,field_name,blob)
      super #=> returns blob[:tempfile]
    end
  end
end

Application.initializer(ROOT_PATH)