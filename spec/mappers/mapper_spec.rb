
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActivityMapper do
   before(:each) do 
     @json = %Q{   
       [{
       "statecode":"Scheduled",
        "cssi_disposition":"Select a Disposition",
        "scheduledend":"3/4/2011 4:00:00 PM",
        "regardingobjectid":
          { 
            "type":"opportunity",
            "name":"Frankliny, Benjamin - 2/9/2011",
            "id":"10b8f740-6e34-e011-a625-0050569c157c"
          },
        "statuscode":"Busy",
        "subject":"Appointment with Frankliny, Benjamin - 2/9/2011",
        "scheduledstart":"3/4/2011 3:30:00 PM"
        }]
      }
  end
    
  it "should parse json into a redis-ready hash" do
    result = ActivityMapper.map_json(@json).first[1]
    
    result["statecode"].should == "Scheduled"
    result["scheduledstart"].should == "3/4/2011 3:30:00 PM"
    result["parent_type"].should == "opportunity"
    result["subject"].should == "Appointment with Frankliny, Benjamin - 2/9/2011"
    result["parent_id"].should == "10b8f740-6e34-e011-a625-0050569c157c"
  end
end

describe NoteMapper do
  before(:each) do 
     @json = %Q{[{
       "annotationid":"41354137-e454-e011-93bf-0050569c7cfe",
       "subject":"Note created on 3/22/2011 7:25 PM by James Burkett",
       "notetext":"Test note #1",
       "objectid":
         {
           "type":null,
           "name":null,
           "id":"07526ecc-1f54-e011-93bf-0050569c7cfe"},
           "createdon":"03/22/2011 07:26:38 PM",
           "modifiedon":"03/22/2011 07:26:38 PM",
           "objecttypecode":"opportunity"
         }]
       }
  end
  
  it "should parse json into a redis-ready hash" do
    result = NoteMapper.map_json(@json).first[1]
    # ap result
    
    result["modifiedon"].should == "03/22/2011 07:26:38 PM"
    result["parent_type"].should == "opportunity"
    result["subject"].should == "Note created on 3/22/2011 7:25 PM by James Burkett"
    result["parent_id"].should == "07526ecc-1f54-e011-93bf-0050569c7cfe"
    result["notetext"].should == "Test note #1"
    result["createdon"].should == "03/22/2011 07:26:38 PM"
    result["annotationid"].should == "41354137-e454-e011-93bf-0050569c7cfe"
    result["objecttypecode"].should == nil
    
  end
end










