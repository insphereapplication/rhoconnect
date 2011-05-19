require File.expand_path(File.dirname(__FILE__) + '/boot.rb')
require 'helpers/crypto'

class Application < Rhosync::Base
  class << self
    def authenticate(username,password,session)
      ExceptionUtil.rescue_and_reraise do
        InsiteLogger.info "Logging onto #{CONFIG[:crm_path]}session/logon"
        response = RestClient.post "#{CONFIG[:crm_path]}session/logon", :username => username, :password => password
        InsiteLogger.info "Response.code = #{response.inspect}"
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
Store.db = Redis.new(:thread_safe => true, :host => CONFIG[:redis_url], :port => CONFIG[:redis_port], :timeout => CONFIG[:redis_timeout])

