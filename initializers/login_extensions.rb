module Rhosync
  class Server
    def do_login
      begin
        login ? status(200) : status(401)
      rescue RestClient::Forbidden => fe
        throw :halt, [403, fe.message]
      rescue LoginException => le
        throw :halt, [401, le.message]
      rescue Exception => e
        throw :halt, [500, e.message]
      end
    end
  end
end