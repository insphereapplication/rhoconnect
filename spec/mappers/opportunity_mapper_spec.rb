require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rest-client'
require 'active_support/core_ext'

describe OpportunityMapper do 
  it_should_behave_like "SpecHelper"
  
  before(:all) do
    @current_user = Object.new
    def @current_user.login
       "testuser" 
    end
  end
  
  # before(:each) do
  #   raw_opps_query = JSON
  #   JSON.stub!(:parse).and_return(RAW_OPPS_QUERY)
  #   RestClient.stub!(:post).and_return('')
  #   setup_test_for Opportunity, @current_user.login
  #   @early_opp_id = "d2db3339-4d64-e011-90a3-0050569c2250"
  #   @late_opp_id = "d66659f2-a864-e011-90a3-0050569c2250"
  # end
  #   
  # it "should process Opportunity query" do
  #   JSON.stub!(:parse).and_return(RAW_OPPS_QUERY)
  #   RestClient.stub!(:post).and_return('')
  #   test_query.size.should > 0
  #   query_errors.should == {}
  # end
  
  
  it "should send down conflict fields if last_activity_date in Redis is earlier than last_activity_date on the client" do
    # RedisUtil.stub!(:get_model).and_return({:cssi_lastactivitydate => 2.days.ago.to_s})
        
    client_lad = 1.day.ago.to_s
    
    result = OpportunityMapper.map_data_from_client({
      :id => @early_opp_id,   
      :cssi_lastactivitydate => client_lad,
      :statuscode => 'client status',
      :statecode => 'client state'
    }, @current_user)

    result[:statuscode].should ==  'client status'
    result[:statecode].should == 'client state'
    result[:cssi_lastactivitydate].should == client_lad
    
  end

  
  it "should not send down conflict fields if last_activity_date in Redis is earlier than last_activity_date on the client" do
    RedisUtil.stub!(:get_model).and_return({:cssi_lastactivitydate => 1.day.ago.to_s})
    
    current_user = Object.new
    def current_user.login; end
    
    client_lad = 2.days.ago.to_s
    
    result = OpportunityMapper.map_data_from_client({
      :cssi_lastactivitydate => client_lad,
      :statuscode => 'client status',
      :statecode => 'client state'
    }, current_user)

    result[:statuscode].should be_nil
    result[:statecode].should be_nil
    result[:cssi_lastactivitydate].should be_nil
    
  end
end

RAW_OPPS_QUERY = [
      {
                     "modifiedon" => "2011-04-14 09:03:22",
                      "statecode" => "Open",
               "cssi_inputsource" => "Integrated",
          "cssi_lastactivitydate" => 1.day.ago.to_s,
                     "contact_id" => "d0db3339-4d64-e011-90a3-0050569c2250",
                  "opportunityid" => "d2db3339-4d64-e011-90a3-0050569c2250",
           "cssi_assignedagentid" => {
              "name" => "James Burkett",
                "id" => "b0b67403-0902-df11-a6f1-0050568d2fb2",
              "type" => "systemuser"
          },
              "cssi_statusdetail" => "Call Back Requested",
               "cssi_fromrhosync" => "False",
               "cssi_callcounter" => "2",
                      "createdon" => "2011-04-11 10:06:16",
                     "statuscode" => "Contact Made"
      },
      {
                          "statecode" => "Open",
                         "modifiedon" => "2011-04-18 00:02:03",
                    "cssi_leadtypeid" => "Other",
                  "cssi_leadvendorid" => "InsureMe (LeadForward)",
              "cssi_lastactivitydate" => 2.days.ago.to_s,
                   "cssi_inputsource" => "Manual",
                  "cssi_leadsourceid" => "PDL",
                      "cssi_leadcost" => "100.0000",
                         "contact_id" => "d46659f2-a864-e011-90a3-0050569c2250",
                      "opportunityid" => "d66659f2-a864-e011-90a3-0050569c2250",
               "cssi_assignedagentid" => {
                  "name" => "James Burkett",
                    "id" => "b0b67403-0902-df11-a6f1-0050568d2fb2",
                  "type" => "systemuser"
              },
                   "cssi_fromrhosync" => "False",
                  "cssi_statusdetail" => "No Answer",
                   "cssi_callcounter" => "1",
                "cssi_lineofbusiness" => "Health",
                          "createdon" => "2011-04-11 21:02:48",
                         "statuscode" => "No Contact Made"
          }
      
  ]
    
