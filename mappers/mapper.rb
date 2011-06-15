class Mapper
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
  
  def self.convert_type_name(type)
    type.downcase == 'phonecall' ? 'PhoneCall' : type.capitalize
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