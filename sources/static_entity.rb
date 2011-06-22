class StaticEntity < SourceAdapter
  def initialize(source,credential)
    ExceptionUtil.rescue_and_reraise do
      @staticentity_url = "#{CONFIG[:crm_path]}staticentity"
      super(source,credential)
    end
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      @username = Store.get_value("username:#{current_user.login.downcase}:username")
      
      encryptedPassword = Store.get_value("username:#{current_user.login.downcase}:password")
      @password = Crypto.decrypt( encryptedPassword )
      
      @initialized_key = "username:#{current_user.login.downcase}:dependent:initialized"
    end
  end
 
  def query(params=nil)
    ExceptionUtil.rescue_and_reraise do
      InsiteLogger.info "QUERY FOR STATICENTITIES FOR #{current_user.login.downcase}"
      
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
      
      @result = {
                  "1" => {"names" => carriers, "type" => "carriers"},
                  "2" => {"names" => lobs, "type" => "line_of_business"},
                  "3" => {"names" => rawlead_lobs, "type" => "rawlead_lineofbusiness"},
                  "4" => {"names" => lead_sources, "type" => "lead_source"}
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