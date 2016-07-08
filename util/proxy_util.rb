module DuplicateDetectionUtil  
  def get_duplicate_id(create_hash)
    get_link(get_temp_id(create_hash))
  end
  
  def create_link(temp_id, crm_id)
    Store.get_store(0).db.hset(links_hash_key, temp_id, crm_id)
  end
  
  def get_link(temp_id)
    Store.get_store(0).db.hget(links_hash_key, temp_id)
  end
  
  def get_temp_id(create_hash)
    create_hash['temp_id']
  end
  
  def links_hash_key
    "create_links:#{@source.user_id}:#{@source.name}"
  end
end

module ReplaceTempID
  def replace_with_guid(create_hash,temp_id_name,type)
    temp_id = create_hash[temp_id_name]
    #After upgrade to 5.4 the temp_id_ is incase in {} for some reason
    temp_id = temp_id.blank? ? temp_id : temp_id.gsub("{","").gsub("}","")
    if (!temp_id.blank? && !temp_id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      InsiteLogger.info(:format_and_join => ["Replacing Tempid for : #{temp_id_name}, temp_id:  #{temp_id}."])
      result = Store.get_store(0).db.hget(find_hash_key(type), temp_id)
      InsiteLogger.info(:format_and_join => ["Temp id result lookup: ",result])
      if (result)     
        create_hash[temp_id_name] = result  
        InsiteLogger.info(:format_and_join => ["Replaced Tempid for : #{temp_id_name}, temp_id:  #{temp_id} with #{result}."])
      end
    end  
    create_hash
  end
  
  def find_hash_key(type)
    "create_links:#{@source.user_id}:#{type}"
  end
  
end

module ProxyUtil
  #assumes that @username, @password, @mapper_context and @source are defined
  include DuplicateDetectionUtil
  def proxy_update(update_hash,mapper_context={})
    mapped_hash = Mapper.load(self.class.name).map_data_from_client(update_hash.clone, mapper_context)
    InsiteLogger.info(:format_and_join => ["Proxy update: #{@proxy_update_url}, update_hash: ",update_hash,", mapped_hash: ",mapped_hash])
    result = RestClient.post(@proxy_update_url, 
        {:username => @username, 
        :password => @password,
        :attributes => mapped_hash.to_json}
      ).body
    
    UpdateUtil.push_update(@source, update_hash)
    result
  end
  
  def proxy_create(create_hash,mapper_context={})
    # Check for duplicate
    temp_id = get_temp_id(create_hash)
    result = get_duplicate_id(create_hash)
    unless result
      # If no duplicate, create in proxy
      mapped_hash = Mapper.load(self.class.name).map_data_from_client(create_hash.clone, mapper_context)
      InsiteLogger.info(:format_and_join => ["Proxy create: #{@proxy_create_url}, create_hash: ",create_hash,", mapped_hash: ",mapped_hash])
      result = RestClient.post(@proxy_create_url,
          {:username => @username,
           :password => @password,
           :attributes => mapped_hash.to_json}
      ).body
      create_link(temp_id,result) unless temp_id.nil?
    else
      InsiteLogger.info(:format_and_join => ["Record #{result} for temp id #{temp_id} already created; ignoring create: ",create_hash])
      create_hash.clear # Ensure that we don't touch what is already in redis / add duplicate attribute value keys in the master document
    end
    result
  end
  
  def proxy_delete(delete_hash)
    InsiteLogger.info(:format_and_join => ["Proxy delete: #{@proxy_delete_url}, delete_hash: ",delete_hash])
    result = RestClient.post(@proxy_delete_url,
        {:username => @username,
         :password => @password,
         :attributes => delete_hash.to_json}
    ).body
    result
  end
end