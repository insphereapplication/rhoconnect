
class ApplicationDetailMapper < Mapper

  def self.map_data_from_client(data)
    data.reject!{|k,v| ['temp_id'].include?(k)}
    data  
  end
  
  def map_from_source_hash(app_detail_mapper)
    app_detail_mapper.map! do |value| 
      #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
      #these fields are not modified from rhodes and should only be injected in map_data_from_client as needed
      value.reject!{|k,v|  ['ownerid', 'temp_id'].include?(k) }
      value
    end
    app_detail_mapper.reduce({}){|sum, value| sum[value["applicationid"]] = value if value; sum }
  end

end