['api', 'initializers'].each { |dir| Dir[File.join(File.dirname(__FILE__),dir,'**','*.rb')].each { |file| load file }}

class Application < Rhosync::Base
  class << self
    def authenticate(username,password,session)
      puts "Authentication requested #{username}:#{password}"
      puts "Logging to #{CONFIG[:crm_path]}session/logon"
      response = RestClient.post "#{CONFIG[:crm_path]}session/logon", :username => username, :password => password
      if response.code == 200
        Store.put_value("username:#{username}:token", response.body.strip.gsub(/"/, ''))
        return true
      elsif response.code == 401
        return false
      end   
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