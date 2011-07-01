module ProxyUtil
  #assumes that @username, @password, @mapper_context and @source are defined
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
    mapped_hash = Mapper.load(self.class.name).map_data_from_client(create_hash.clone, mapper_context)
    InsiteLogger.info(:format_and_join => ["Proxy create: #{@proxy_create_url}, create_hash: ",create_hash,", mapped_hash: ",mapped_hash])
    result = RestClient.post(@proxy_create_url,
        {:username => @username,
         :password => @password,
         :attributes => mapped_hash.to_json}
    ).body
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