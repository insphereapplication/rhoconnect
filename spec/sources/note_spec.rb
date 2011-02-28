require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Note" do
  it_should_behave_like "SpecHelper"
  
  before(:each) do
    setup_test_for Note,'testuser'
  end
  
  it "should process Note query" do
    pending
  end
  
  it "should process Note create" do
    pending
  end
  
  it "should process Note update" do
    pending
  end
  
  it "should process Note delete" do
    pending
  end
end