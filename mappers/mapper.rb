class Mapper
  def map_json(data, type)
    parsed_values = JSON.parse(data)
    parsed_values.reduce({}){|sum, value| sum[value["#{type}id"]] = value; sum }
  end
  
  def self.load(source_type)
    Object.const_get("#{source_type.capitalize}Mapper")
  rescue
    Mapper
  end
end