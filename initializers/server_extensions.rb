
module Rhosync
  class SourceAdapter
    def self.on_api_push(&block)
      @@api_pushed = block
    end
    
    def self.api_pushed(user_id)
      @@api_pushed.call(user_id) if @@api_pushed
    end
  end
end