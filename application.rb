class Application < Rhosync::Base
  # @@login_url = "http://localhost:5000/session/logon"
  @@login_url = "http://75.31.122.27/session/logon"
  class << self
    def authenticate(username,password,session)
      puts "@"*80 + " Authentication requested"
      response = RestClient.post @@login_url, :username => username, :password => password
                 
      puts "*********** AUTHENTICATED: #{username} -- #{password}"
      puts "*********** AuthToken: #{response.body.strip.gsub(/"/, '')}"
     
      if response.code == 200
        Store.put_value("username:#{username}:token", response.body.strip.gsub(/"/, ''))
        success = true
      end
 
      return success
    end
    
    def initializer(path)
      super
    end
    
    # Calling super here returns rack tempfile path:
    # i.e. /var/folders/J4/J4wGJ-r6H7S313GEZ-Xx5E+++TI
    # Note: This tempfile is removed when server stops or crashes...
    # See http://rack.rubyforge.org/doc/Multipart.html for more info
    # 
    # Override this by creating a copy of the file somewhere
    # and returning the path to that file (then don't call super!):
    # i.e. /mnt/myimages/soccer.png
    def store_blob(object,field_name,blob)
      super #=> returns blob[:tempfile]
    end
  end
end

Application.initializer(ROOT_PATH)