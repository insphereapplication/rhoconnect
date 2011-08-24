class Mapper
  class TypeName
    attr_accessor :crm, :mobile
    def initialize(crm, mobile)
      @crm = crm
      @mobile = mobile
    end
  end
  
  class Lookup
    attr_accessor :crm_name, :mobile_type_attribute, :mobile_id_attribute
    def initialize(crm_name, mobile_type_attribute, mobile_id_attribute)
      @crm_name = crm_name
      @mobile_type_attribute = mobile_type_attribute
      @mobile_id_attribute = mobile_id_attribute
    end

    def inject_crm_lookups!(data)
      if data[@mobile_type_attribute] || data[@mobile_id_attribute]
        data.merge!({@crm_name => Lookup.build_crm_lookup(data[@mobile_type_attribute], data[@mobile_id_attribute])})
        data.reject!{|k,v| [@mobile_type_attribute, @mobile_id_attribute].include?(k)}
      end
      data
    end

    def inject_mobile_attributes!(data)
      lookup = data[@crm_name] 
      unless lookup.nil?
        data.reject!{|k,v| k == @crm_name}
        data.merge!(Lookup.split_crm_lookup(lookup, @mobile_type_attribute, @mobile_id_attribute)) unless lookup.blank?
      end
      data
    end

    class << self
      def build_crm_lookup(type, id)
        {
          'type' => Mapper.convert_mobile_type(type),
          'id' => id
        }
      end

      def split_crm_lookup(lookup, type_attribute_name, id_attribute_name)
        {
          id_attribute_name => lookup['id'], 
          type_attribute_name => Mapper.convert_crm_type(lookup['type'])
        }
      end
    end
  end
  
  TYPE_NAMES = [
    TypeName.new("phonecall","PhoneCall"),
    TypeName.new("cssi_policy","Policy")
  ]
  
  def self.map_source_data(data, source_name)
    mapper = load(source_name)
    mapper.map_source_data(data)
  end
  
  def self.map_data_from_client(data, source_name)
    mapper = load(source_name)
    mapper.map_data_from_client(data)
  end
  
  def self.load(source_name)
    begin 
      Object.const_get("#{source_name}Mapper").new
    rescue
      return Mapper.new(source_name)
    end
  end
  
  def self.convert_crm_type(type)
    type_name = TYPE_NAMES.select{|tn| tn.crm.downcase == type.downcase }.first
    type_name.nil? ? type.capitalize : type_name.mobile
  end
  
  def self.convert_mobile_type(type)
    type_name = TYPE_NAMES.select{|tn| tn.mobile.downcase == type.downcase }.first
    type_name.nil? ? type.downcase : type_name.crm
  end
  
  def initialize(source_name=nil)
    @source_name = source_name
  end
  
  def map_source_data(data)
    data_hash = data.kind_of?(Array) ? data : JSON.parse(data)
    map_from_source_hash(data_hash)
  end
  
  def map_from_source_hash(data_hash)
    data_hash.reduce({}){|sum, value| sum[value["#{@source_name.downcase}id"]] = value; sum }
  end
  
  def map_data_from_client(data, mapper_context={})
    data
  end
  
end