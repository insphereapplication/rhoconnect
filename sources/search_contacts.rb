app_path = File.expand_path(File.join(File.dirname(__FILE__))) 
require "#{app_path}/../util/redis_util"

class SearchContacts < SourceAdapter
  
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @search_contact_url = "#{CONFIG[:crm_path]}contact/search"
      InsiteLogger.info "************************Initializing SearchContacts"
      super(source,credential)
    end
  end
  
  def search(params)
    ExceptionUtil.rescue_and_reraise do
      RedisUtil.clear_md('SearchContacts', current_user.login.downcase)
    
      InsiteLogger.info "************************ Searching"
      InsiteLogger.info params
      
      result = RestClient.post(@search_contact_url,
          {:username => @username,
           :password => @password,
           :attributes => params.to_json},
           :content_type => :json
      ).body
         
      # hard-coding PK to 1 -- this is basically a singleton object for the user. There 
      # will be one search results representing the results of the last search term
      @result = { 1 => {
          :terms => params.to_json,
          :results => Mapper.map_source_data(result, 'Contact').to_json
        }
      }
      
      InsiteLogger.info @result
      
    end
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )      
    end
  end
 
  def query(params=nil)

  end
 
  def sync
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhosync::Store interface.
    # By default, super is called below which simply saves @result
    #super
  end
 
  def create(create_hash,blob=nil)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "************************SEARCHING CRM CONTACTS for #{current_user.login.downcase}"
      if create_hash
        ExceptionUtil.context(:current_user => current_user.login)
     
        #clear the search master doc
        InsiteLogger.info "************************Clearing Search master doc"
        RedisUtil.clear_md('SearchContacts',current_user.login.downcase)
    
        InsiteLogger.info "************************Calling rest client at #{@search_contact_url}"
        res = RestClient.post(@search_contact_url,
            {:username => @username,
             :password => @password,
             :attributes => create_hash.to_json},
             :content_type => :json
        ).body
              
        InsiteLogger.info "************************ PARSING "
        parsed = Mapper.map_source_data(JSON.parse(res), 'SearchContacts')
        InsiteLogger.info parsed

        create_hash.merge!({'contact_search_results' => parsed.to_json})
        
        InsiteLogger.info create_hash

        # InsiteLogger.info "************************Parsing JSON..."
        # result = JSON.parse(res)
        # ap result
               
        InsiteLogger.info "************************Done!"
        ExceptionUtil.context(:result => res )
                
        Time.now.to_i
      end
    end
  end
 
  def update(update_hash)
    # TODO: Update an existing record in your backend data source
    #raise "Search adapter does not implement an Update method"
  end
 
  def delete(delete_hash)
    #raise "Search adapter does not implement a Delete method"
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end
end