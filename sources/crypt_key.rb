class CryptKey < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
   
  end
 
  def query(params=nil)
    settings = YAML::load_file('settings/settings.yml')
    mobile_crypt_key = settings[:global][:app_info][:mobile_crypt_key]
    #ap "*** Crypt key is:  #{mobile_crypt_key} ***"
    @result = { "1" => { :mobile_crypt_key => mobile_crypt_key } }
    
  end
 
  def sync
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhosync::Store interface.
    # By default, super is called below which simply saves @result
    super
  end
 
  def create(create_hash,blob=nil)
   
  end
 
  def update(update_hash)
    
  end
 
  def delete(delete_hash)
   
  end
 
  def logoff
  
  end
end