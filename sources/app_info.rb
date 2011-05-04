$settings_file = 'settings/settings.yml'
$config = YAML::load_file($settings_file)

class AppInfo < SourceAdapter
  def initialize(source,credential)
    ap "AppInfo.initialize"
    super(source,credential)
  end
 
  def login
    # TODO: Login to your data source here if necessary
  end
 
  def query(params=nil)
    ap "AppInfo.query"
    mrv = CONFIG[:minimum_required_version]
    ap "*** Client should be using at least version #{mrv} ***"
    @result = { "1" => { :min_required_version => mrv } }
    
    # YAML::load_file("")
    # TODO: Query your backend data source and assign the records 
    # to a nested hash structure called @result. For example:
    # @result = { 
    #   "1"=>{"name"=>"Acme", "industry"=>"Electronics"},
    #   "2"=>{"name"=>"Best", "industry"=>"Software"}
    # }
    # raise SourceAdapterException.new("Please provide some code to read records from the backend data source")
  end
 
  def sync
    ap "AppInfo.sync"
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhosync::Store interface.
    # By default, super is called below which simply saves @result
    super
  end
 
  def create(create_hash,blob=nil)
    ap "AppInfo.create"
    # TODO: Create a new record in your backend data source
    # If your rhodes rhom object contains image/binary data 
    # (has the image_uri attribute), then a blob will be provided
    # raise "Please provide some code to create a single record in the backend data source using the create_hash"
  end
 
  def update(update_hash)
    ap "AppInfo.update"
    # TODO: Update an existing record in your backend data source
    # raise "Please provide some code to update a single record in the backend data source using the update_hash"
  end
 
  def delete(delete_hash)
    ap "AppInfo.delete"
    # TODO: write some code here if applicable
    # be sure to have a hash key and value for "object"
    # for now, we'll say that its OK to not have a delete operation
    # raise "Please provide some code to delete a single object in the backend application using the object_id"
  end
 
  def logoff
    ap "AppInfo.logoff"
    # TODO: Logout from the data source if necessary
  end
end