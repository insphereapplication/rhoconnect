require "#{ROOT_PATH}/load_test/rhoconnect_session"


describe RhoconnectSession do
  before(:each) do 
    class RhoconnectSession
       def initialize(*args)
         @base_url = args[0]
       end
    end # don't attempt to connect
    
    RhoconnectSession.clear_local_serialized
  end
  
  it "should create a url args string" do
    session = RhoconnectSession.new()
    session.client_id = "1"
    session.url_args(:test => "test").should == "test=test&p_size=2000&client_id=1"
  end
  
  it "should serialize itself" do 
    session = RhoconnectSession.new
    session.client_id = "1"
    session.base_url = "www.www.www"
    session.persist_local
    reloaded = RhoconnectSession.load
    reloaded.client_id.should == session.client_id
    reloaded.base_url.should == session.base_url
  end
  
  it "should create a new session if one doesn't exist" do
    session = RhoconnectSession.load_or_create("fu.bar.com", "Obama", "Pariveda1")
    session.base_url.should == "fu.bar.com"
  end
end