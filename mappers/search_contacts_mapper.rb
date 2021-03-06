
class SearchContactsMapper < Mapper
  def map_from_source_hash(contact_array)
    InsiteLogger.info "************************Mapping search results"
    contact_array.map! do |value| 
      #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
      #these fields are not modified from rhodes and should only be injected in map_data_from_client as needed
      value.reject!{|k,v|  ['ownerid'].include?(k) }
      value
    end
    contact_array.reduce({}){|sum, value| sum[value["contactid"]] = value if value; sum }
  end  
  
  def self.map_data_from_client(data)    
    data.reject!{|k,v| ['temp_id'].include?(k)}
    data
  end  
end