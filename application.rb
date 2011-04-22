require File.expand_path(File.dirname(__FILE__) + '/boot.rb')

class Application < Rhosync::Base
  class << self
    def authenticate(username,password,session)
      puts "Authentication requested #{username}:#{password}"
      ap "Logging onto #{CONFIG[:crm_path]}session/logon"
      response = RestClient.post "#{CONFIG[:crm_path]}session/logon", :username => username, :password => password
      ap "Response.code = #{response.inspect}"
      success = false
      if response && response.code == 200
        #get user's CRM ID, cache it for later use
        crm_user_id = response.body.strip.gsub(/"/, '')
        
        ap "User #{username} has identity #{crm_user_id}"
        
        Store.put_value("username:#{username.downcase}:username", username)
        Store.put_value("username:#{username.downcase}:password", password)
        Store.put_value("username:#{username.downcase}:crm_user_id", crm_user_id)
    
        success = true
      end
      
      return success 
    end
    
    def initializer(path)
      admin = User.is_exist?('rhoadmin') ? User.load('rhoadmin') : User.create({:login => 'rhoadmin', :admin => 1})
      admin.password = CONFIG[:rhoadmin_password] || ''
      admin.create_token
      super
    end
    
    def store_blob(object,field_name,blob)
      super #=> returns blob[:tempfile]
    end
  end
end

Application.initializer(ROOT_PATH)

