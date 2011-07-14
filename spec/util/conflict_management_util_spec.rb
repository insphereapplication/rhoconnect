require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rest-client'
require 'active_support/core_ext'

class FakeUser
  def login
    "robert.zimmerman"
  end
end

describe ConflictManagementUtil do 
  # it_should_behave_like "SpecHelper"
  
  before(:all) do
    @early_opp_id = "1234567890"
    @current_user = Object.new
    def @current_user.login
       "testuser" 
    end
  end
  
  it "should reject the conflict fields and return if no cssi_lastactivitydate is given" do 
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
      'cssi_lastactivitydate' => "Fri May 27 17:21:53 -0500 2011"
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
      'cssi_lastactivitydate' => "Fri May 27 17:21:53 -0500 2011"
    }
    returned = ConflictManagementUtil.manage_opportunity_conflicts(client_fields, FakeUser.new)
    returned.should == {}
  end
  
  it "should reject all fields and return if the existing opp is won" do
    lost_opp = {'statecode' => 'Lost'}
    
    RedisUtil.stub(:get_model).and_return(lost_opp)
    
    client_fields = {
      'statuscode' => 'fu', 
      'statecode' => 'bar', 
      'cssi_statusdetail' => 'fu', 
      'hey' => 'hey',
      'cssi_lastactivitydate' => "Fri May 27 17:21:53 -0500 2011"
    }
    returned = ConflictManagementUtil.manage_opportunity_conflicts(client_fields, FakeUser.new)
    returned.should == {}
  end
  
  it "should not reject all fields and return if the existing opp is not won or lost" do
    won_opp = {'statecode' => 'Blah'}
    
    RedisUtil.stub(:get_model).and_return(won_opp)
    
    client_fields = {
      'statuscode' => 'fu', 
      'statecode' => 'bar', 
      'cssi_statusdetail' => 'fu', 
      'hey' => 'hey',
      'cssi_lastactivitydate' => "Fri May 27 17:21:53 -0500 2011"
    }
    returned = ConflictManagementUtil.manage_opportunity_conflicts(client_fields, FakeUser.new)
    returned.should_not == {}
  end
  
  it "should not reject any fields if the redis record has no last_activity_date" do
    no_lad_in_redis = {'fu' => 'bar'}
    
    RedisUtil.stub(:get_model).and_return(no_lad_in_redis)
    
    client_fields = {
      'statuscode' => 'fu', 
      'statecode' => 'bar', 
      'cssi_statusdetail' => 'fu', 
      'hey' => 'hey',
      'cssi_lastactivitydate' => "Fri May 27 17:21:53 -0500 2011"
    }
    returned = ConflictManagementUtil.manage_opportunity_conflicts(client_fields, FakeUser.new)
    returned.should == client_fields
  end
  
  it "should send down conflict fields if last_activity_date in Redis is earlier than last_activity_date on the client" do
     RedisUtil.stub!(:get_model).and_return({'cssi_lastactivitydate' => 2.days.ago.to_s})
         
     client_lad = 1.day.ago.to_s
     
     result = ConflictManagementUtil.manage_opportunity_conflicts({
       'id' => @early_opp_id,   
       'cssi_lastactivitydate' => client_lad,
       'statuscode' => 'client status',
       'statecode' => 'client state'
     }, FakeUser.new)
  
     result['statuscode'].should ==  'client status'
     result['statecode'].should == 'client state'
     result['cssi_lastactivitydate'].should == client_lad
   end
   
  it "should not reject updates if the last activity date from the client is less than 5 minutes behind that of CRM" do
    RedisUtil.stub!(:get_model).and_return({'cssi_lastactivitydate' => Time.now.to_s})
    
    client_lad = 4.5.minutes.ago.to_s
    
    result = ConflictManagementUtil.manage_opportunity_conflicts({
       'id' => @early_opp_id,   
       'cssi_lastactivitydate' => client_lad,
       'statuscode' => 'client status',
       'statecode' => 'client state'
     }, FakeUser.new)
  
     result['statuscode'].should ==  'client status'
     result['statecode'].should == 'client state'
     result['cssi_lastactivitydate'].should == client_lad
  end
  
    it "should not send down conflict fields if last_activity_date in Redis is earlier than last_activity_date on the client" do
      RedisUtil.stub!(:get_model).and_return({'cssi_lastactivitydate' => Time.now.to_s})
      
      current_user = Object.new
      def current_user.login; end
      
      client_lad = 5.1.minutes.ago.to_s
      
      result = ConflictManagementUtil.manage_opportunity_conflicts({
        'cssi_lastactivitydate' => client_lad,
        'statuscode' => 'client status',
        'statecode' => 'client state',
        'hey' => 'what'
      }, current_user)
   
      result.should == {'hey' => 'what'}
      
    end
end

