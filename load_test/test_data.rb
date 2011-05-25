require 'uuidtools'

module TestData
  class << self
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
                      "statuscode" => statuscode
      }
      res
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

