
class PolicyMapper < Mapper
  
  def map_from_source_hash(policy_array)
    policy_array.map! do |value| 
      carrier_id = value['cssi_carrierid']
      unless carrier_id.nil?
        value.reject!{|k,v| k == 'cssi_carrierid'}
        value.merge!({'carrier_id' => carrier_id['id'], 'carrier_name' => carrier_id['name']}) unless carrier_id.blank?
      end
      
      product_id = value['cssi_productid']
      unless product_id.nil?
        value.reject!{|k,v| k == 'cssi_productid'}
        value.merge!({'product_id' => product_id['id'], 'product_name' => product_id['name']}) unless product_id.blank?
      end
      
      contact_id = value['cssi_contactid']
      unless contact_id.nil?
        value.reject!{|k,v| k == 'cssi_contactid'}
        value.merge!({'contact_id' => contact_id['id']}) unless contact_id.blank?
      end
      
      #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
      #these fields are not modified from rhodes and should only be injected in map_data_from_client as needed
      value.reject!{|k,v|  ['ownerid'].include?(k) }
      
      value
    end
    policy_array.reduce({}){|sum, value| sum[value["cssi_policyid"]] = value if value; sum }
  end
  
  def map_data_from_client(data, mapper_context={})
    data.reject!{|k,v| ['temp_id'].include?(k)}
    data
  end
end