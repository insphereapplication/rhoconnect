class AppInfo < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
    # TODO: Login to your data source here if necessary
  end
 
  def query(params=nil)
    settings = YAML::load_file('settings/settings.yml')
    ap "*** Settings file = #{settings[:global][:app_info].inspect}"
    mrv = settings[:global][:app_info][:min_required_version]
    apple_url = settings[:global][:app_info][:apple_force_upgrade_url]
    android_url = settings[:global][:app_info][:android_force_upgrade_url]
    ap "*** Client should be using at least version #{mrv} ***"
    ap "*** Apple Upgrade URL is #{apple_url} ***"
    ap "*** Android Upgrade URL is #{android_url} ***"
    @result = { "1" => { :min_required_version => mrv, :apple_upgrade_url => apple_url, :android_upgrade_url => android_url } }
    
    # TODO: Query your backend data source and assign the records 
    # to a nested hash structure called @result. For example:
    # @result = { 
    #   "1"=>{"name"=>"Acme", "industry"=>"Electronics"},
    #   "2"=>{"name"=>"Best", "industry"=>"Software"}
    # }
    # raise SourceAdapterException.new("Please provide some code to read records from the backend data source")
  end
 
  def sync
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhosync::Store interface.
    # By default, super is called below which simply saves @result
    super
  end
 
  def create(create_hash,blob=nil)
    # TODO: Create a new record in your backend data source
    # If your rhodes rhom object contains image/binary data 
    # (has the image_uri attribute), then a blob will be provided
    # raise "Please provide some code to create a single record in the backend data source using the create_hash"
  end
 
  def update(update_hash)
    # TODO: Update an existing record in your backend data source
    # raise "Please provide some code to update a single record in the backend data source using the update_hash"
  end
 
  def delete(delete_hash)
    # TODO: write some code here if applicable
    # be sure to have a hash key and value for "object"
    # for now, we'll say that its OK to not have a delete operation
    # raise "Please provide some code to delete a single object in the backend application using the object_id"
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end
end