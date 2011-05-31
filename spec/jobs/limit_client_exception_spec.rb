require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe LimitClientExceptions do 
  
  before(:each) do
    username = "huddie.ledbetter"
    @exception_key = "source:application:#{username}:ClientException:md"
    Rhosync::Store.put_data(@exception_key, EXCEPTIONS)
    Rhosync::Store.put_value("user:#{username}:rho__id", username)
    LimitClientExceptions.stub(:client_exception_limit).and_return(@limit = 3)
  end
  
  it "should remove clients exceptions past the given limit" do
    Rhosync::Store.get_data(@exception_key).size.should == 5
    LimitClientExceptions.perform
    Rhosync::Store.get_data(@exception_key).size.should == @limit
  end
  
  it "should remove the oldest exceptions first" do
    Rhosync::Store.get_data(@exception_key).size.should == 5
    LimitClientExceptions.perform
    Rhosync::Store.get_data(@exception_key).keys.should == ["1306527343", "1306527344", "1306527404"]
  end
  
  it "should reset the count value" do
    
  end
  
end

EXCEPTIONS = {
    "1306527343" => {
            "has_network" => "true",
           "exception_id" => "1306527343",
              "device_id" => "",
             "os_version" => "4.2",
        "client_platform" => "APPLE",
          "rho_device_id" => "22cfd88bed134ae5a5d8ea7d3705b1ce",
                "message" => "Error in SyncNotify for user 'dave.sims': Unhandled error in sync_notify: 8 -- Could not connect to data server. {\"total_count\"=>\"349\", \"processed_count\"=>\"0\", \"cumulative_count\"=>\"0\", \"source_id\"=>\"3\", \"source_name\"=>\"Opportunity\", \"sync_type\"=>\"incremental\", \"status\"=>\"error\", \"error_code\"=>\"8\", \"error_message\"=>\"\", \"server_errors\"=>{\"update-error\"=>{\"c3ecba0b-eb87-e011-90a3-0050569c2250\"=>{\"message\"=>\"getaddrinfo: nodename nor servname provided, or not known\", \"attributes\"=>{\"cssi_lastactivitydate\"=>\"2011-05-27 15:15:43\", \"cssi_statusdetail\"=>\"Left Message\", \"cssi_fromrhosync\"=>\"true\", \"statuscode\"=>\"No Contact Made\"}}}}, \"rho_callback\"=>\"1\"}",
            "device_name" => "iPhone Simulator",
              "backtrace" => ""
    },
    "1306527465" => {
           "exception_id" => "1306527465",
            "has_network" => "true",
              "device_id" => "",
             "os_version" => "4.2",
        "client_platform" => "APPLE",
          "rho_device_id" => "22cfd88bed134ae5a5d8ea7d3705b1ce",
            "device_name" => "iPhone Simulator",
                "message" => "Error in SyncNotify for user 'dave.sims': Unhandled error in sync_notify: 8 -- Could not connect to data server. {\"total_count\"=>\"87\", \"processed_count\"=>\"0\", \"cumulative_count\"=>\"0\", \"source_id\"=>\"8\", \"source_name\"=>\"Activity\", \"sync_type\"=>\"incremental\", \"status\"=>\"error\", \"error_code\"=>\"8\", \"error_message\"=>\"\", \"server_errors\"=>{\"create-error\"=>{\"75737402122835.0\"=>{\"message\"=>\"getaddrinfo: nodename nor servname provided, or not known\", \"attributes\"=>{\"location\"=>\"\", \"statecode\"=>\"Completed\", \"phonenumber\"=>\"\", \"scheduledstart\"=>\"\", \"activityid\"=>\"\", \"cssi_phonetype\"=>\"\", \"parent_type\"=>\"Opportunity\", \"subject\"=>\"Phone Call - Aurelio Carter\", \"cssi_location\"=>\"\", \"parent_contact_id\"=>\"94a3b4ff-ea87-e011-90a3-0050569c2250\", \"cssi_fromrhosync\"=>\"\", \"cssi_dispositiondetail\"=>\"\", \"type\"=>\"PhoneCall\", \"parent_id\"=>\"c3ecba0b-eb87-e011-90a3-0050569c2250\", \"scheduledend\"=>\"2011-05-27 15:15:43\", \"description\"=>\"\", \"cssi_disposition\"=>\"Left Message\", \"statuscode\"=>\"Made\", \"createdon\"=>\"\"}}}}, \"rho_callback\"=>\"1\"}",
              "backtrace" => ""
    },
    "1306527344" => {
            "has_network" => "true",
           "exception_id" => "1306527344",
              "device_id" => "",
             "os_version" => "4.2",
        "client_platform" => "APPLE",
          "rho_device_id" => "22cfd88bed134ae5a5d8ea7d3705b1ce",
            "device_name" => "iPhone Simulator",
                "message" => "Error in SyncNotify for user 'dave.sims': Unhandled error in sync_notify: 8 -- Could not connect to data server. {\"total_count\"=>\"87\", \"processed_count\"=>\"0\", \"cumulative_count\"=>\"0\", \"source_id\"=>\"8\", \"source_name\"=>\"Activity\", \"sync_type\"=>\"incremental\", \"status\"=>\"error\", \"error_code\"=>\"8\", \"error_message\"=>\"\", \"server_errors\"=>{\"create-error\"=>{\"75737402122835.0\"=>{\"message\"=>\"getaddrinfo: nodename nor servname provided, or not known\", \"attributes\"=>{\"location\"=>\"\", \"statecode\"=>\"Completed\", \"phonenumber\"=>\"\", \"scheduledstart\"=>\"\", \"activityid\"=>\"\", \"cssi_phonetype\"=>\"\", \"parent_type\"=>\"Opportunity\", \"subject\"=>\"Phone Call - Aurelio Carter\", \"cssi_location\"=>\"\", \"parent_contact_id\"=>\"94a3b4ff-ea87-e011-90a3-0050569c2250\", \"cssi_fromrhosync\"=>\"\", \"cssi_dispositiondetail\"=>\"\", \"type\"=>\"PhoneCall\", \"parent_id\"=>\"c3ecba0b-eb87-e011-90a3-0050569c2250\", \"scheduledend\"=>\"2011-05-27 15:15:43\", \"description\"=>\"\", \"cssi_disposition\"=>\"Left Message\", \"statuscode\"=>\"Made\", \"createdon\"=>\"\"}}}}, \"rho_callback\"=>\"1\"}",
              "backtrace" => ""
    },
    "1306527404" => {
           "exception_id" => "1306527404",
            "has_network" => "true",
              "device_id" => "",
             "os_version" => "4.2",
        "client_platform" => "APPLE",
          "rho_device_id" => "22cfd88bed134ae5a5d8ea7d3705b1ce",
                "message" => "Error in SyncNotify for user 'dave.sims': Update error -- {\"total_count\"=>\"349\", \"processed_count\"=>\"0\", \"cumulative_count\"=>\"0\", \"source_id\"=>\"3\", \"source_name\"=>\"Opportunity\", \"sync_type\"=>\"incremental\", \"status\"=>\"error\", \"error_code\"=>\"8\", \"error_message\"=>\"\", \"server_errors\"=>{\"update-error\"=>{\"c3ecba0b-eb87-e011-90a3-0050569c2250\"=>{\"message\"=>\"getaddrinfo: nodename nor servname provided, or not known\", \"attributes\"=>{\"cssi_lastactivitydate\"=>\"2011-05-27 15:15:43\", \"cssi_statusdetail\"=>\"Left Message\", \"cssi_fromrhosync\"=>\"true\", \"statuscode\"=>\"No Contact Made\"}}}}, \"rho_callback\"=>\"1\"}",
            "device_name" => "iPhone Simulator",
              "backtrace" => ""
    },
    "1306527405" => {
           "exception_id" => "1306527405",
            "has_network" => "true",
              "device_id" => "",
             "os_version" => "4.2",
        "client_platform" => "APPLE",
          "rho_device_id" => "22cfd88bed134ae5a5d8ea7d3705b1ce",
            "device_name" => "iPhone Simulator",
                "message" => "Error in SyncNotify for user 'dave.sims': Unhandled error in sync_notify: 8 -- Could not connect to data server. {\"total_count\"=>\"87\", \"processed_count\"=>\"0\", \"cumulative_count\"=>\"0\", \"source_id\"=>\"8\", \"source_name\"=>\"Activity\", \"sync_type\"=>\"incremental\", \"status\"=>\"error\", \"error_code\"=>\"8\", \"error_message\"=>\"\", \"server_errors\"=>{\"create-error\"=>{\"75737402122835.0\"=>{\"message\"=>\"getaddrinfo: nodename nor servname provided, or not known\", \"attributes\"=>{\"location\"=>\"\", \"statecode\"=>\"Completed\", \"phonenumber\"=>\"\", \"scheduledstart\"=>\"\", \"activityid\"=>\"\", \"cssi_phonetype\"=>\"\", \"parent_type\"=>\"Opportunity\", \"subject\"=>\"Phone Call - Aurelio Carter\", \"cssi_location\"=>\"\", \"parent_contact_id\"=>\"94a3b4ff-ea87-e011-90a3-0050569c2250\", \"cssi_fromrhosync\"=>\"\", \"cssi_dispositiondetail\"=>\"\", \"type\"=>\"PhoneCall\", \"parent_id\"=>\"c3ecba0b-eb87-e011-90a3-0050569c2250\", \"scheduledend\"=>\"2011-05-27 15:15:43\", \"description\"=>\"\", \"cssi_disposition\"=>\"Left Message\", \"statuscode\"=>\"Made\", \"createdon\"=>\"\"}}}}, \"rho_callback\"=>\"1\"}",
              "backtrace" => ""
    }
}