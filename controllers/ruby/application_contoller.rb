require "#{Rhoconnect.app_directory}/boot.rb"

class ApplicationController < Rhoconnect::Controller::AppBase
    register Rhoconnect::EndPoint

    post "/login", :rc_handler => :authenticate,
             :deprecated_route => {:verb => :post, :url => ['/application/clientlogin', '/api/application/clientlogin']} do
        username = params[:login]
        password = params[:password]
		
        ExceptionUtil.rescue_and_reraise do
        InsiteLogger.info "Logging user #{username} onto #{CONFIG[:crm_path]}session/logon"
        response = RestClient.post("#{CONFIG[:crm_path]}session/logon", { :username => username, :password => password })

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
        InsiteLogger.info "Logging user #{username} was successful: #{success}" 
        return success 
      end
    end

    get "/rps_login", :rc_handler => :rps_authenticate,
                    :login_required => true do
        login = params[:login]
        password = params[:password]
        puts "IS this used???????"
    end

    # <.... PLACE HERE ALL OF YOUR EXISTING APPLICATION CODE ...>
end
