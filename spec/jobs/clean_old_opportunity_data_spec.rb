require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe CleanOldOpportunityData do 
  
  # before(:each) do
  #   username = "huddie.ledbetter"
  #   @exception_key = "source:application:#{username}:ClientException:md"
  #   Rhoconnect::Store.put_data(@exception_key, Opportunities)
  #   Rhoconnect::Store.put_value("user:#{username}:rho__id", username)
  # end
  # 
  # it "should remove clients exceptions past the given limit" do
  #   Rhoconnect::Store.get_data(@exception_key).size.should == 5
  #   CleanOldOpportunityData.perform
  #   Rhoconnect::Store.get_data(@exception_key).size.should == @limit
  # end
  # 
  # it "should remove the oldest exceptions first" do
  #   Rhoconnect::Store.get_data(@exception_key).size.should == 5
  #   CleanOldOpportunityData.perform
  #   Rhoconnect::Store.get_data(@exception_key).keys.should == ["1306527343", "1306527344", "1306527404"]
  # end
  
  it "should reset the count value" do
    
  end
  
end