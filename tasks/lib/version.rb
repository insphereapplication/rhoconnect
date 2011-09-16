class Version
  include Comparable
  def initialize(version)
    @version = Version.split_version(version)
  end
  
  def split
    @version
  end
  
  def joined
    split.join('.')
  end
  
  def <=>(other)
    other_split = other.split
    split.each_with_index do |v,i|
      compared = v <=> (other_split[i] || 0)
      return compared if compared != 0
    end
    return 0
  end
  
  def self.split_version(version)
    version.gsub(/[^0-9^\.]/,'').split('.')
  end
end