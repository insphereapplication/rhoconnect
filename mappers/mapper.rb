class Mapper
  def self.map_source_data(data, source_name)
    mapper = load(source_name)
    mapper.map_source_data(data)
  end
  
  def initialize(source_name=nil)
    @source_name = source_name
  end
  
  def self.load(source_name)
    begin 
      Object.const_get("#{source_name.capitalize}Mapper").new
    rescue
      return Mapper.new(source_name)
    end
  end
  
  def map_source_data(data)
    data_hash = data.kind_of?(Array) ? data : JSON.parse(data)
    map_from_source_hash(data_hash)
  end
  
  def map_from_source_hash(data_hash)
    data_hash.reduce({}){|sum, value| sum[value["#{@source_name.downcase}id"]] = value; sum }
  end
end