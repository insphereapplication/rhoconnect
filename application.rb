require File.expand_path(File.dirname(__FILE__) + '/boot.rb')

class Application < Rhosync::Base
  class << self
    def authenticate(username,password,session)
      puts "Authentication requested #{username}:#{password}"
      ap "Logging onto #{CONFIG[:crm_path]}session/logon"
      response = RestClient.post "#{CONFIG[:crm_path]}session/logon", :username => username, :password => password
      ap response.to_s
      success = false
      if response.code == 200
        new_token = response.body.strip.gsub(/"/, '')
        
        begin
          #get old token, logout from proxy if it exists
          old_token = Store.get_value("username:#{username.downcase}:token")
          if old_token
            ap "Found old token #{old_token}, logging it out from proxy"
            logout_response = RestClient.post "#{CONFIG[:crm_path]}session/logout", {:token => old_token}
            ap "Logout response code #{logout_response.code}"
          end
        rescue
          ap "Error while removing old token"
        end
        
        #get user's CRM ID, cache it for later use
        whoami_response = JSON.parse(RestClient.post("#{CONFIG[:crm_path]}user/whoami", 
          {:token => new_token},
          :content_type => :json
        ))
        
        ap "User #{username} has identity #{whoami_response['id']}"
        
        Store.put_value("username:#{username.downcase}:crm_user_id", whoami_response['id'])
        
        Store.put_value("username:#{username.downcase}:token", new_token)
        success = true
      end
      
      return success 
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