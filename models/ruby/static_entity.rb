class StaticEntity < Rhoconnect::Model::Base
  def initialize(source)
    ExceptionUtil.rescue_and_reraise do
      @staticentity_url = "#{CONFIG[:crm_path]}staticentity"
      super(source)
    end
  end
 
  def login
    ExceptionUtil.rescue_and_reraise do
      UserUtil.enable_if_disabled(current_user.login)
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
      
      #ap "Carriers: #{carriers}"
      
      lob_res = JSON.parse(RestClient.post(@staticentity_url, {:username => @username,
                                                               :password => @password,
                                                               :entityname => "cssi_lineofbusiness"},
                                                               :content_type => :json))
                                                    
      lobs = ""
      lob_res.each do |lob|
        lobs << lob << "||"
      end               

      #ap "LOB Entity options: #{lobs}"                               

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
      
      #ap "Raw Lead LOB picklist options: #{rawlead_lobs}"                               

      lead_source_res = JSON.parse(RestClient.post(@staticentity_url, {:username => @username,
                                                                       :password => @password,
                                                                       :entityname => "cssi_leadsource"},
                                                                       :content_type => :json))
                                                                       
      lead_sources = ""
      lead_source_res.each do |lead_source|
        lead_sources << lead_source << "||"
      end             
            
      #ap "Lead sources: #{lead_sources}"                 


      role_source_res = JSON.parse(RestClient.post("#{CONFIG[:crm_path]}user/Roles",
                                                                    {:username => @username,
                                                                     :password => @password},
                                                                     :content_type => "application/x-www-form-urlencoded"))

      can_reassign_opportunities = (role_source_res & CONFIG[:opp_assign_roles].split(',')).length >= 1 ? true : false                                                               
                                                                     
      downline_source_res = RestClient.post("#{CONFIG[:crm_path]}user/Downline",
                                                                    {:username => @username,
                                                                     :password => @password},
                                                                     :content_type => "application/x-www-form-urlencoded")


      whoami_source = JSON.parse(RestClient.post("#{CONFIG[:crm_path]}user/WhoAmI",
                                                     {:username => @username,
                                                      :password => @password},
                                                      :content_type => "application/x-www-form-urlencoded"))
      who_am_i_id =   whoami_source['id']                                                             
            
      ExceptionUtil.context(:result => @result)          
      
      @result = {
                  "1" => {"names" => carriers, "type" => "carriers"},
                  "2" => {"names" => lobs, "type" => "line_of_business"},
                  "3" => {"names" => rawlead_lobs, "type" => "rawlead_lineofbusiness"},
                  "4" => {"names" => lead_sources, "type" => "lead_source"},
                  "5" => {"names" => can_reassign_opportunities, "type" => "reassign_capability"},
                  "6" => {"names" => downline_source_res, "type" => "downline_source"},
                  "7" => {"names" => who_am_i_id, "type" => "systemuserid"},
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