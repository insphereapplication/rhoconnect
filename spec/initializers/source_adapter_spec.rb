require File.join(File.dirname(__FILE__),'..','spec_helper')
# require File.join(File.dirname(__FILE__), '../..', 'initializers/source_adapter_extensions')

describe "SourceAdapter" do
  it_should_behave_like "SpecHelper"

  it "should check the arity of the block passed to on_api_pushed" do 
    
    lambda {
      class BadAdapter < SourceAdapter
        on_api_push do
          # no arg for this block is bad
        end
      end
    }.should raise_error("API Push block must take a single argument for passing the user id")
  end
end

class TestAdapter < SourceAdapter
  on_api_push do |user_id|
    TestAdapter.api_push_method
  end
  
  def self.api_push_method; end
  
end