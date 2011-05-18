
class PolicyMapper < Mapper
  def map_from_source_hash(policy_array)
    #ap "policy_array = #{policy_array}"
    
    policy_array.map! do |value| 
      #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
      #these fields are not modified from rhodes and should only be injected in map_data_from_client as needed
      value.reject!{|k,v|  ['ownerid'].include?(k) }
      value
    end
    policy_array.reduce({}){|sum, value| sum[value["cssi_policyid"]] = value if value; sum }
  end
  
  def self.map_data_from_client(data)
    data
  end
end