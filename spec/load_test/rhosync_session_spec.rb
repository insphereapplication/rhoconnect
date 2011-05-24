app_path = File.expand_path(File.dirname(__FILE__))
require "#{app_path}/../spec_helper"
require "#{app_path}/../../load_test/rhosync_session"


describe RhosyncSession do
  it "should " do
    class RhosyncSession; def initialize; end; end; # don't attempt to connect
    session = RhosyncSession.new
    session.client_id = "1"
    session.url_args(:test => "test").should == "test=test&p_size=2000&client_id=1"
  end
end