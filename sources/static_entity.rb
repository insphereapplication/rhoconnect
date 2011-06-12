class StaticEntity < SourceAdapter
  def initialize(source,credential)
    InsiteLogger.info "******************** Calling initialize from StaticEntity ********************"
    ExceptionUtil.rescue_and_reraise do
      @staticentity_url = "#{CONFIG[:crm_path]}staticentity"
      super(source,credential)
    end
  end
 
  def login
    InsiteLogger.info "******************** Calling login from StaticEntity ********************"
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:dependent:initialized"
    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "QUERY FOR STATICENTITIES for #{current_user.login.downcase}"
      
      carrier_res = JSON.parse(RestClient.post(@staticentity_url, {:username => @username,
                                                        :password => @password,
                                                        :entityname => "cssi_carrier"},
                                                        :content_type => :json))
      
      carriers = ""
      carrier_res.each do |carrier|
        carriers << carrier << "||"
      end
      
      ap "Carriers: #{carriers}"
      
      lob_res = JSON.parse(RestClient.post(@staticentity_url, {:username => @username,
                                                               :password => @password,
                                                               :entityname => "cssi_lineofbusiness"},
                                                               :content_type => :json))
                                                    
      lobs = ""
      lob_res.each do |lob|
        lobs << lob << "||"
      end               

      ap "LOB Entity options: #{lobs}"                               

      rawlead_lob_res = JSON.parse(RestClient.post("#{@staticentity_url}/getattributeoptions",
                                                          {:username => @username,
                                                           :password => @password,
                                                           :entityname => "cssi_rawlead",
                                                           :attributename => "cssi_lineofbusiness"},
                                                           :content_type => :json))
                                                    
      rawlead_lobs = ""
      rawlead_lob_res.each do |lob|
        rawlead_lobs << lob << "||"
      end
      
      ap "Raw Lead LOB picklist options: #{rawlead_lobs}"                               

      lead_source_res = JSON.parse(RestClient.post(@staticentity_url, {:username => @username,
                                                                       :password => @password,
                                                                       :entityname => "cssi_leadsource"},
                                                                       :content_type => :json))
                                                                       
      lead_sources = ""
      lead_source_res.each do |lead_source|
        lead_sources << lead_source << "||"
      end             
            
      ap "Lead sources: #{lead_sources}"                 
      
      ExceptionUtil.context(:result => @result)          
      
      @result = { "carriers" => {"names" => carriers},
                  "line_of_business" => {"names" => lobs},
                  "rawlead_lineofbusiness" => {"names" => rawlead_lobs},
                  "lead_source" => {"names" => lead_sources}
                }
      
      ap "@result = #{@result.inspect}"
    end
  end
 
  def sync
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