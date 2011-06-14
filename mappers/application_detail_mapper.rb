
class ApplicationDetailMapper < Mapper

  def self.map_data_from_client(data)
    data.reject!{|k,v| ['temp_id'].include?(k)}
    data  
  end
  
  def map_from_source_hash(app_detail_mapper)
      app_detail_mapper.map! do |value|

        carrier_id = value['cssi_carrierid']
        unless carrier_id.nil?
          value.reject!{|k,v| k == 'cssi_carrierid'}
          value.merge!({'carrier_id' => carrier_id['id'], 'carrier_name' => carrier_id['name']}) unless carrier_id.blank?
        end

        opportunity_id = value['cssi_opportunityid']
        unless carrier_id.nil?
          value.reject!{|k,v| k == 'cssi_opportunityid'}
          value.merge!({'opportunity_id' => opportunity_id['id']}) unless opportunity_id.blank?
        end

        lineofbusiness_id = value['cssi_lineofbusinessid']
        unless lineofbusiness_id.nil?
          value.reject!{|k,v| k == 'cssi_lineofbusinessid'}
          value.merge!({'lineofbusiness_id' => lineofbusiness_id['id'], 'lineofbusiness_name' => lineofbusiness_id['name']}) unless lineofbusiness_id.blank?
        end

        #always filter out attributes that are only set in RhoSync (avoids problems with fixed schema)
        #these fields are not modified from rhodes and should only be injected in map_data_from_client as needed
        value.reject!{|k,v|  ['ownerid', 'temp_id'].include?(k) }
        value
      end
      app_detail_mapper.reduce({}){|sum, value| sum[value["cssi_applicationid"]] = value if value; sum }
    end


end