class PushHandler
  
  def self.load(source_name)
    begin 
      Object.const_get("#{source_name}PushHandler").new
    rescue
      return PushHandler.new(source_name)
    end
  end
  
  def self.handle_push(source_name, user_id, push_hash)
    load(source_name).handle_push(user_id, push_hash)
  end
    
  def initialize(source_name=nil)
    @source_name = source_name
  end
  
  def handle_push(user_id, push_hash)
    puts "Generic push handler called for user #{user_id} for source #{@source_name}"
  end
end