require 'ap'

class UpdateUtil
  def self.push_objects(source, object_hash)
    redis_hash = {object_hash['id'] => object_hash.reject{ |k,v| k == 'id'}}
    puts "*"*80
    puts "Committing to redis:"
    ap redis_hash
    
    source_sync = SourceSync.new(source)
    source_sync.push_objects(redis_hash)
  end
end