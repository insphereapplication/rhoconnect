app_path = File.expand_path(File.join(File.dirname(__FILE__))) 
require "#{app_path}/boot.rb"

class Application < Rhosync::Base
  class << self
    def authenticate(username,password,session)
      ExceptionUtil.rescue_and_reraise do
        InsiteLogger.info "Logging user #{username} onto #{CONFIG[:crm_path]}session/logon"
        response = RestClient.post "#{CONFIG[:crm_path]}session/logon", :username => username, :password => password
        success = false
        if response && response.code == 200
          #get user's CRM ID, cache it for later use
          crm_user_id = response.body.strip.gsub(/"/, '')
        
          InsiteLogger.info "User #{username} has identity #{crm_user_id}"
        
          encryptedPassword = Crypto.encrypt( password )
          Store.put_value("username:#{username.downcase}:username", username)
          Store.put_value("username:#{username.downcase}:password", encryptedPassword)
          Store.put_value("username:#{username.downcase}:crm_user_id", crm_user_id)
    
          success = true
        end
      
        return success 
      end
    end
    
    def initializer(path)
      super
      admin = User.is_exist?('rhoadmin') ? User.load('rhoadmin') : User.create({:login => 'rhoadmin', :admin => 1})
      admin.password = CONFIG[:rhoadmin_password] || ''
    end
    
    def store_blob(object,field_name,blob)
      super #=> returns blob[:tempfile]
    end
  end
end

Application.initializer(ROOT_PATH)
if CONFIG[:redis_boot]
  if defined?(Store.db.client)
    InsiteLogger.info "Store.db.client is defined, connected?=#{Store.db.client.connected?}. Disconnecting."
    Store.db.client.disconnect
  else
    InsiteLogger.info "Store.db.client isn't defined"
  end
  Store.db = Redis.new(:thread_safe => true, :host => CONFIG[:redis_url], :port => CONFIG[:redis_port], :timeout => CONFIG[:redis_timeout])
end

