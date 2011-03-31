
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Mapper do
  
  it "should use the default mapper when no mapper exists for the given source name" do
    mapper = Mapper.new('Fu')
    Mapper.should_receive(:new).and_return(mapper)
    Mapper.map_source_data([], 'Fu')
  end
  
  it "should use a specific mapper if one is available in the ObjectSpace" do
    mapper = ActivityMapper.new
    ActivityMapper.should_receive(:new).and_return(mapper)
    Mapper.map_source_data([{"test"=>"stuff"}], 'Activity')
  end
  
  it "should properly fetch the id attribute from a given contact hash" do
    mapper = Mapper.new('Contact')
    Mapper.should_receive(:new).and_return(mapper)
    mapped_result = Mapper.map_source_data([{"contactid"=>"1234", "firstname" => "BobFirst"}], "Contact")
    
    ap mapped_result
    
    mapped_result.keys[0].should == '1234'
  end
  
  it "should properly fetch the id attribute from a given opportunity hash" do
    mapper = Mapper.new('Opportunity')
    Mapper.should_receive(:new).and_return(mapper)
    mapped_result = Mapper.map_source_data([{"opportunityid"=>"4321", "firstname" => "BobFirst"}], "Opportunity")
    
    ap mapped_result
    
    mapped_result.keys[0].should == '4321'
  end
  
  it 'should convert type names' do
    Mapper.convert_type_name('blah').should == 'Blah'
    Mapper.convert_type_name('phoneCall').should == 'PhoneCall'
  end
  
  
end

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
        "scheduledstart":"3/4/2011 3:30:00 PM",
        "cssi_skipdispositionworkflow":"true"
        }]
      }
  end
  
  it "should return an ActivityMapper" do
    Mapper.load('Activity').should be_kind_of(ActivityMapper)
  end
    
  it "should parse json into a redis-ready hash" do
    result = Mapper.map_source_data(@json, "Activity").first[1]
    
    result["statecode"].should == "Scheduled"
    result["scheduledstart"].should == "3/4/2011 3:30:00 PM"
    result["parent_type"].should == "opportunity"
    result["subject"].should == "Appointment with Frankliny, Benjamin - 2/9/2011"
    result["parent_id"].should == "10b8f740-6e34-e011-a625-0050569c157c"
    result["cssi_skipdispositionworkflow"].should == nil
  end
  
  it "should inject cssi_skipdispositionworkflow when cssi_disposition is provided from the client" do
    result = ActivityMapper.map_data_from_client({
      'unchanged' => '1234',
      'cssi_disposition' => 'blah'
    })
    
    result['unchanged'].should == '1234'
    result['cssi_disposition'].should == 'blah'
    result['cssi_skipdispositionworkflow'].should == 'true'
  end
  
  
  
  it "should not inject cssi_skipdispositionworkflow when cssi_disposition is not provided from the client" do
    result = ActivityMapper.map_data_from_client({
      'unchanged' => '1234',
      'cssi_leadsourceid' => 'Newspaper'
    })
    
    result['unchanged'].should == '1234'
    result['cssi_leadsourceid'].should == 'Newspaper'
    result['cssi_skipdispositionworkflow'].should == nil
  end
  
  it "should construct regardingobjectid whenever a parent_type or parent_id is provided and reject the client-side referential keys" do
    result = ActivityMapper.map_data_from_client({
      'shouldnotbetouched' => '1234',
      'parent_type' => 'opportunity',
      'parent_id' => '5678'
    })
    
    result['shouldnotbetouched'].should == '1234'
    result['parent_type'].should == nil
    result['parent_id'].should == nil
    result['regardingobjectid'].should include('id','type')
    result['regardingobjectid']['id'].should == '5678'
    result['regardingobjectid']['type'].should == 'opportunity'
  end

  it "should not construct regardingobjectid whenever parent_type and parent_id are not provided" do
    result = ActivityMapper.map_data_from_client({
      'shouldnotbetouched' => '1234',
      'shouldnotbetouched2' => '5678'
    })

    result['shouldnotbetouched'].should == '1234'
    result['shouldnotbetouched2'].should == '5678'
    result.should_not include('regardingobjectid','parent_id','parent_type')
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
    result = Mapper.map_source_data(@json, 'Note').first[1]
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










