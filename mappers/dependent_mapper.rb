class DependentMapper < Mapper
  def map_from_source_hash(dependent_array)
    dependent_array.map! do |value| 
      
      contact_id = value['cssi_contactdependentsid']
      unless contact_id.nil?
        value.reject!{|k,v| k == 'cssi_contactdependentsid'}
        value.merge!({'contact_id' => contact_id['id']}) unless contact_id.blank?
      end
      
      #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
      #these fields are not modified from rhodes and should only be injected in map_data_from_client as needed
      value.reject!{|k,v|  ['ownerid'].include?(k) }
      value
    end
    dependent_array.reduce({}){|sum, value| sum[value["cssi_dependentsid"]] = value if value; sum }
  end
  
  def self.map_data_from_client(data)
    data
  end
end