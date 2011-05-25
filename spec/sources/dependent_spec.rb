require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Dependent" do
  it_should_behave_like "SpecHelper"
  
  before(:each) do
    setup_test_for Dependent,'testuser'
  end
  
  it "should process Dependent query" do
    pending
  end
  
  it "should process Dependent create" do
    pending
  end
  
  it "should process Dependent update" do
    pending
  end
  
  it "should process Dependent delete" do
    pending
  end
end