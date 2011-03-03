module Rhosync
  class SourceAdapter
    def self.on_api_push(&block)
      @@api_push_observer = block
    end
    
    def self.notify_api_pushed(user_id)
      @@api_push_observer.call(user_id) if @@api_push_observer
    end
  end
end