require 'uuidtools'
require 'faker'

module TestData
  class << self
    $states = ["AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"]

    $lead_sources = ['Internet','Direct Mail','E-Mail','Newspaper','Other','PDL','Radio','Referral']

    $lead_vendors = ['AllWeb','Humana','InsureMe','iPipeline','Most Choice']

    $lead_types = ['Agent Website','Banner','Classified','Other','Search']
    
    def rand_activity_state
       ['Open','Completed'][rand(2)]
     end

     def rand_array_item(array)
     	array[rand(array.count)]
     end

     def rand_state
     	rand_array_item($states)
     end

     def rand_month
     	rand(12) + 1
     end

     def rand_day
     	rand(28) + 1
     end

     def rand_year
     	(1930 + rand(70)).to_s
     end

     def rand_gender
     	['Male','Female'][rand(2)]
     end

     def rand_tf
       ['True','False'][rand(2)]
     end

     def rand_height_feet
       rand_height_feet = rand(3) + 4
     end

     def rand_height_inches
       rand_height_inches = rand(11)
     end

     def rand_weight
       rand_weight = rand(250) + 100
     end

     def rand_marital_status
       ['Single','Married','Divorced','Widowed'][rand(4)]
     end
    
    def create_activity_json(type, statecode, parent_contact_id, parent_id, parent_type, statuscode)
      {
                       "statecode" => statecode,
                        "location" => "",
                     "phonenumber" => "",
                  "scheduledstart" => "",
                      "activityid" => "",
                     "parent_type" => parent_type,
                  "cssi_phonetype" => "",
                         "subject" => "Load Test For Great Justice!",
                   "cssi_location" => "",
               "parent_contact_id" => parent_contact_id,
          "cssi_dispositiondetail" => "",
                            "type" => type,
                "cssi_fromrhosync" => "",
                       "parent_id" => parent_id,
                    "scheduledend" => "2011-04-20 16:39:01",
                "cssi_disposition" => "",
                     "description" => "",
                      "statuscode" => statuscode
      }.to_json
    end
  
    # assume for now all notes are owned by PhoneCalls
    def create_note_json(parent_id)
      {
            "modifiedon" => "",
           "parent_type" => "PhoneCall",
               "subject" => "",
             "parent_id" => parent_id,
             "createdon" => "2011-04-20 16:39:01",
              "notetext" => "This is a note created in a load test.",
          "annotationid" => ""
      }.to_json
    end
  
    def create_phone_call(parent_id, parent_contact_id, disposition, statecode = "", statuscode = "")
      res = {}
      mock_id = UUIDTools::UUID.random_create.to_s.gsub(/\-/,'')
      
      res[mock_id] = 
      {
                  "scheduledstart" => "2011-04-21 17:00:00",
                      "object" => mock_id,
                     "phonenumber" => "",
                  "cssi_phonetype" => "",
                     "parent_type" => "Opportunity",
                   "cssi_location" => "Home",
                         "subject" => "Jaeden, Prohaska - 2011-04-07 11:31:24",
               "parent_contact_id" => parent_contact_id,
          "cssi_dispositiondetail" => "",
                            "type" => "PhoneCall",
                       "parent_id" => parent_id,
                    "scheduledend" => "2011-04-21 18:30:00",
                     "description" => "",
                "cssi_disposition" => disposition, #"Left Message"/"Contact Made"/"No Answer"
                       "statecode" => statecode,
                      "statuscode" => statuscode,
                         "temp_id" => mock_id                   
      }
      res
    end  
    
    def create_left_message_phone_call_data(parent_id, parent_contact_id)
      data = {}
      endTime = Time.now + (2*24*60*60)
      data[parent_id] = 
      {                  
                  "statecode" => "Completed",
                  "parent_type" => "Opportunity",
                  "subject" => "Phone Call - Load test", 
                  "type" => "PhoneCall", 
                  "parent_contact_id" => parent_contact_id, 
                  "parent_id" => parent_id,
                  "scheduledend" => endTime.strftime("%Y-%m-%d %H:%M:%S"), 
                  "temp_id" => "96724910339908.1",
                  "cssi_disposition" => "Left Message",
                  "createdon" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                  "statuscode" => "Made"           
      }
      data
    end
    
    
    def get_fake_contact_data()
      fake_data = {}
     	preferred_phone = ['Home','Mobile','Business'][rand(3)]

       first_name = Faker::Name.first_name
       last_name = Faker::Name.last_name
       email = "#{first_name}.#{last_name}@loadtest.net"
       #'ownerid' => {'type' => 'systemuser', 'id' => identity['id']},
     	fake_data[1] = {
     		'address1_city' => Faker::Address.city,
     		'address1_line1' => Faker::Address.street_address,
     		'cssi_state1id' => rand_state,
     		'address2_city' => Faker::Address.city,
     		'address2_line1' => Faker::Address.street_address,
     		'cssi_state1id' => rand_state,
     		'firstname' => first_name,
     		'lastname' => last_name,
     		'emailaddress1' => email,
     		'birthdate' => "#{rand_year}/#{rand_month}/#{rand_day}",
     		'cssi_preferredphone' => preferred_phone,
     		'mobilephone' => Faker::Base.numerify('(###) ###-####'),
     		'telephone1' => Faker::Base.numerify('(###) ###-####'),
     		'telephone2' => Faker::Base.numerify('(###) ###-####'),
     		'gendercode' => rand_gender,
     		'cssi_heightft' => rand_height_feet,
     		'cssi_heightin' => rand_height_inches,
     		'cssi_weight' => rand_weight,
     		'cssi_usetobacco' => rand_tf,
     		'familystatuscode' => rand_marital_status,
     		'cssi_allowcallsalternatephone' => rand_tf,
     		'cssi_allowcallsbusinessphone' => rand_tf,
     		'cssi_allowcallshomephone' => rand_tf,
     		'cssi_allowcallsmobilephone' => rand_tf,
     		'cssi_spousename' => Faker::Name.first_name,
     		'cssi_spouselastname' => Faker::Name.last_name,
     		'cssi_spousebirthdate' => "#{rand_year}/#{rand_month}/#{rand_day}",
     		'cssi_spouseheightft' => rand_height_feet,
     		'cssi_spouseheightin' => rand_height_inches,
     		'cssi_spouseweight' => rand_weight,
     		'cssi_spouseusetobacco' => rand_tf,
     		'cssi_spousegender' => rand_gender
     	};
     	fake_data
     end
     
     def get_fake_opportunity_data(contact_id)
      #'ownerid' => {'type' => 'systemuser', 'id' => identity['id']}, 
      fake_data = {}
     	fake_data[1] = {
     		'contact_id' => contact_id,
     		'cssi_leadsourceid' => rand_array_item($lead_sources),
     		'cssi_leadvendorid' => rand_array_item($lead_vendors),
     		'cssi_leadtypeid' => rand_array_item($lead_types),
     		'cssi_inputsource' => 'Integrated',
     		'status_update_timestamp' => Time.now.utc.to_s, 
        'cssi_lastactivitydate' => Time.now.strftime("%Y-%m-%d %H:%M:%S")
     	};
     	fake_data
     end
     
     def update_opportunity_left_message(opportunity_id)
      update_data = {}
      update_data [opportunity_id] = { 
        "status_update_timestamp" => Time.now.utc.to_s, 
        "cssi_lastactivitydate" => Time.now.strftime("%Y-%m-%d %H:%M:%S"), 
        "id" => opportunity_id,
        "cssi_statusdetail" => "Left Message" 
      }
      update_data
      end
      
    def get_activity_updated(type, activity_id, disposition, statecode, statuscode = "")
      res = {}
      res[activity_id] =
      {
          "cssi_skipdispositionworkflow" => "true",
                             "statecode" => statecode,
                            "activityid" => activity_id,
                      "cssi_fromrhosync" => "true",
                                  "type" => type,
                          "scheduledend" => "2011-04-21 10:55:37",
                      "cssi_disposition" => disposition, #"Left Message"/"Contact Made"/"No Answer"
                            "statuscode" => statuscode 
      }
      res
    end
  
    def get_opportunity_updated(opportunity_id, disposition)
      res = {}
      res[opportunity_id] =
      {
          "cssi_lastactivitydate" => "2011-04-21 10:55:37",
                             "id" => opportunity_id,
                    "statuscode" => "No Contact Made",
               "cssi_fromrhosync" => "true",
              "cssi_statusdetail" => disposition #"Left Message"/"Contact Made"/"No Answer"
      }
      res
    end
  end
end

# UPDATE ACTIVITY -- SUBMITTED ATTRS:
{
       "statecode" => "Completed",
              "id" => "0304342b-3c6c-e011-ae7d-0050569c001e",
         "subject" => "Phone Call - Fausto Buckridge",
    "scheduledend" => "2011-04-21 17:38:16",
      "statuscode" => "Made"
}
# CURRENT ACTIVITY ATTRS:
{
            "statecode" => "Open",
           "activityid" => "0304342b-3c6c-e011-ae7d-0050569c001e",
          "parent_type" => "Opportunity",
              "subject" => "Jaeden, Prohaska - 2011-04-07 11:31:24",
                 "type" => "PhoneCall",
    "parent_contact_id" => "b3f9c108-3461-e011-9db6-0050569c001e",
         "scheduledend" => "2011-04-21 18:30:00",
            "parent_id" => "cae1f97c-3461-e011-9db6-0050569c001e",
     "cssi_disposition" => "Left Message",
           "statuscode" => "Open"
}
{
           "statecode" => "Completed",
             "subject" => "Phone Call - Fausto Buckridge",
                  "id" => "0304342b-3c6c-e011-ae7d-0050569c001e",
    "cssi_fromrhosync" => "true",
                "type" => "PhoneCall",
        "scheduledend" => "2011-04-21 17:38:16",
          "statuscode" => "Made"
}

