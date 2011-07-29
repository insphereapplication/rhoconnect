require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rest-client'
require 'active_support/core_ext'

class FakeUser
  def login
    "robert.zimmerman"
  end
end

describe ConflictManagementUtil do 
  
  def stub_last_update(time=Time.now)
    update_history_util = mock("UpdateHistoryUtil")
    update_history_util.stub!(:last_update).and_return(time)
    UpdateHistoryUtil.stub!(:new).and_return(update_history_util)
  end
  
  before(:all) do
    @early_opp_id = "1234567890"
    @current_user = Object.new
    def @current_user.login
       "testuser" 
    end
    @dummy_opp = {"opportunityid" => "12345", "contactid" => "54321"}
  end
  
  it "should reject the conflict fields and return if no status_update_timestamp is given" do 
    no_lad = {
      'statuscode' => 'fu', 
      'statecode' => 'bar', 
      'cssi_statusdetail' => 'fu', 
      'hey' => 'hey'
    }
    
    returned = ConflictManagementUtil.manage_opportunity_conflicts(no_lad, FakeUser.new)
    returned.should == {'hey' => 'hey'}
  end
  
  it "should reject all fields and return if the existing opp is won" do
    won_opp = {'statecode' => 'Won'}
    
    RedisUtil.stub(:get_model).and_return(won_opp)
    
    client_fields = {
      'statuscode' => 'fu', 
      'statecode' => 'bar', 
      'cssi_statusdetail' => 'fu', 
      'hey' => 'hey',
      'status_update_timestamp' => "Fri May 27 17:21:53 -0500 2011"
    }
    returned = ConflictManagementUtil.manage_opportunity_conflicts(client_fields, FakeUser.new)
    returned.should == {}
  end
  
  it "should reject all fields and return if the opp does not exist in redis" do    
    RedisUtil.stub(:get_model).and_raise(RedisUtil::RecordNotFound)
    
    client_fields = {
      'statuscode' => 'fu', 
      'statecode' => 'bar', 
      'cssi_statusdetail' => 'fu', 
      'hey' => 'hey',
      'status_update_timestamp' => "Fri May 27 17:21:53 -0500 2011"
    }
    
    returned = ConflictManagementUtil.manage_opportunity_conflicts(client_fields, FakeUser.new)
    returned.should == {}
  end
  
  it "should reject all fields and return if the existing opp is lost" do
    lost_opp = {'statecode' => 'Lost'}
    
    RedisUtil.stub(:get_model).and_return(lost_opp)
    
    client_fields = {
      'statuscode' => 'fu', 
      'statecode' => 'bar', 
      'cssi_statusdetail' => 'fu', 
      'hey' => 'hey',
      'status_update_timestamp' => "Fri May 27 17:21:53 -0500 2011"
    }
    returned = ConflictManagementUtil.manage_opportunity_conflicts(client_fields, FakeUser.new)
    returned.should == {}
  end
  
  it "should not reject all fields and return if the existing opp is not won or lost" do
    won_opp = {'statecode' => 'Blah'}
    
    RedisUtil.stub(:get_model).and_return(won_opp)
      
    stub_last_update(nil)
    
    client_fields = {
      'statuscode' => 'fu', 
      'statecode' => 'bar', 
      'cssi_statusdetail' => 'fu', 
      'hey' => 'hey',
      'status_update_timestamp' => "Fri May 27 17:21:53 -0500 2011"
    }
    returned = ConflictManagementUtil.manage_opportunity_conflicts(client_fields, FakeUser.new)
    returned.should_not == {}
  end
  
  it "should not reject any fields if there is no known last update to the status fields" do
    RedisUtil.stub!(:get_model).and_return(@dummy_opp)
      
    stub_last_update(nil)
    
    client_fields = {
      'statuscode' => 'fu', 
      'statecode' => 'bar', 
      'cssi_statusdetail' => 'fu', 
      'hey' => 'hey',
      'status_update_timestamp' => "Fri May 27 17:21:53 -0500 2011"
    }
    returned = ConflictManagementUtil.manage_opportunity_conflicts(client_fields, FakeUser.new)
    returned.should == client_fields
  end
  
  it "should not reject conflict fields last known status field update time is earlier than given last_activity_date from client" do
     RedisUtil.stub!(:get_model).and_return(@dummy_opp)
      
     stub_last_update(2.days.ago)
     
     client_lad = 1.day.ago.to_s
     
     result = ConflictManagementUtil.manage_opportunity_conflicts({
       'id' => @early_opp_id,   
       'status_update_timestamp' => client_lad,
       'statuscode' => 'client status',
       'statecode' => 'client state'
     }, FakeUser.new)
  
     result['statuscode'].should ==  'client status'
     result['statecode'].should == 'client state'
     result['status_update_timestamp'].should == client_lad
   end
   
  it "should not reject updates if the last activity date from the client is less than <configured threshold> seconds behind that of the last status update" do
    RedisUtil.stub!(:get_model).and_return(@dummy_opp)
    
    stub_last_update(Time.now)
    
    client_lad = (CONFIG[:conflict_management_threshold] - 30).seconds.ago.to_s
    
    result = ConflictManagementUtil.manage_opportunity_conflicts({
       'id' => @early_opp_id,   
       'status_update_timestamp' => client_lad,
       'statuscode' => 'client status',
       'statecode' => 'client state'
     }, FakeUser.new)
  
     result['statuscode'].should ==  'client status'
     result['statecode'].should == 'client state'
     result['status_update_timestamp'].should == client_lad
  end
  
    it "should reject conflict fields if the known last status update time is later than the given last_activity_date from the client (including threshold)" do
      RedisUtil.stub!(:get_model).and_return(@dummy_opp)

      stub_last_update(Time.now)

      current_user = Object.new
      def current_user.login; end
      
      client_lad = (CONFIG[:conflict_management_threshold] + 30).seconds.ago.to_s
      
      result = ConflictManagementUtil.manage_opportunity_conflicts({
        'status_update_timestamp' => client_lad,
        'statuscode' => 'client status',
        'statecode' => 'client state',
        'hey' => 'what'
      }, current_user)
   
      result.should == {'hey' => 'what', 'status_update_timestamp' => client_lad}
      
    end
end

