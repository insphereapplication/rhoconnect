require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Mapper" do

  it "should load a default Mapper if none exists for that Source" do
    Mapper.load("blah").should == Mapper
  end
  
  it "should load a specific Mapper if one exists for that Source" do
    Mapper.load("Activity").should == ActivityMapper
  end

end

describe "ActivityMapper" do
  before(:each) do
    @activity_json =   %Q{
        [{"activityid":"1234", "type":"PhoneCall","statecode":"Scheduled","cssi_disposition":"Select a Disposition","scheduledend":"3/4/2011 4:00:00 PM",
        "regardingobjectid":{"type":"opportunity","name":"Frankliny, Benjamin - 2/9/2011","id":"10b8f740-6e34-e011-a625-0050569c157c"},
        "statuscode":"Busy","subject":"Phone call with Frankliny, Benjamin - 2/9/2011","scheduledstart":"3/4/2011 3:30:00 PM"},
        {"activityid":"5678","type":"Appointment","statecode":"Scheduled","cssi_disposition":"Select a Disposition","scheduledend":"3/4/2011 4:00:00 PM",
        "regardingobjectid":{"type":"opportunity","name":"Frankliny, Benjamin - 2/9/2011","id":"10b8f740-6e34-e011-a625-0050569c157c"},
        "statuscode":"Busy","subject":"Appointment with Frankliny, Benjamin - 2/9/2011","scheduledstart":"3/4/2011 3:30:00 PM"}]
      }
    @result = ActivityMapper.map_json(@activity_json)
  end
  
  it "should map each record to its id" do
    @result["1234"].should_not be_nil
    @result["5678"].should_not be_nil
  end
    
  it "should create a statecode field" do
    @result["1234"]['statecode'].should == "Scheduled"
  end
  
  it "should cssi_disposition a subject field" do
    @result["1234"]['cssi_disposition'].should == "Select a Disposition"
  end
  
  it "should create a scheduledend field" do
    @result["1234"]['scheduledend'].should == "3/4/2011 4:00:00 PM"
  end
  
  it "should create a parent_type field" do
    @result["1234"]['parent_type'].should == "opportunity"
  end
  
  it "should create a parent_id field" do
    @result["1234"]['parent_id'].should == "10b8f740-6e34-e011-a625-0050569c157c"
  end
end