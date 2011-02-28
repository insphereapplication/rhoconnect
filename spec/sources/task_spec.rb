require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Task" do
  it_should_behave_like "SpecHelper"
  
  before(:each) do
    setup_test_for Task,'testuser'
  end
  
  it "should process Task query" do
    pending
  end
  
  it "should process Task create" do
    pending
  end
  
  it "should process Task update" do
    pending
  end
  
  it "should process Task delete" do
    pending
  end
end