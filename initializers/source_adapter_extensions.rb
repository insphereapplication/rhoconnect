module Rhosync
  class SourceAdapter
    def self.on_api_push(&block)
      ExceptionUtil.rescue_and_reraise do
        raise "API Push block must take a single argument for passing the user id" unless block.arity == 1
        @api_push_observer = block
      end
    end
    
    def self.notify_api_pushed(user_id)
      ExceptionUtil.rescue_and_reraise do
        @api_push_observer.call(user_id) if @api_push_observer
      end
    end
  end
end