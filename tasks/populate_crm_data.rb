# require 'rest_client'
require 'time'
require 'faker'
require 'ap'

$states = ["AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"]

$lead_sources = ['Internet','Direct Mail','E-Mail','Newspaper','Other','PDL','Radio','Referral']

$lead_vendors = ['AllWeb','Humana','Insphere','InsureMe','iPipeline','Most Choice']

$lead_types = ['Agent Website','Banner','Classified','Mobile Website','Other','Preferred','Search','Shared']

def rand_array_item(array)
	array[rand(array.count)]
end

def rand_state
	rand_array_item($states)
end

def rand_month
	rand_month = rand(12) + 1
end

def rand_day
	rand_day = rand(28) + 1
end

def rand_year
	"19" + rand(100).to_s.rjust(2,'0')
end

def rand_gender
	['Male','Female'][rand(2)]
end

def get_fake_contact_data(identity)
	preferred_phone = ['Home','Mobile','Business'][rand(3)]

	fake_data = {
		'address1_city' => Faker::Address.city,
		'address1_line1' => Faker::Address.street_address,
		'cssi_state1id' => rand_state,
		'address2_city' => Faker::Address.city,
		'address2_line1' => Faker::Address.street_address,
		'cssi_state1id' => rand_state,
		'firstname' => Faker::Name.first_name,
		'lastname' => Faker::Name.last_name,
		'birthdate' => "#{rand_year}/#{rand_month}/#{rand_day}",
		'cssi_preferredphone' => preferred_phone,
		'mobilephone' => Faker::Base.numerify('(###) ###-####'),
		'telephone1' => Faker::Base.numerify('(###) ###-####'),
		'telephone2' => Faker::Base.numerify('(###) ###-####'),
		'gendercode' => rand_gender,
		'cssi_assignedagentid' => {'type' => 'systemuser', 'id' => identity['id']}
	};
	fake_data
end

def get_fake_opportunity_data(contact_id, identity)
	fake_data = {
		'contact_id' => contact_id,
		'cssi_leadsourceid' => rand_array_item($lead_sources),
		'cssi_leadvendorid' => rand_array_item($lead_vendors),
		'cssi_leadtypeid' => rand_array_item($lead_types),
		'cssi_assignedagentid' => {'type' => 'systemuser', 'id' => identity['id']},
		'cssi_inputsource' => 'Integrated'
	};
	fake_data
end

def get_fake_phonecall_data(opportunity_id)
	fake_data = {
		'regardingobjectid' => {'type' => 'opportunity', 'id' => opportunity_id},
		'subject' => "Test Phone Call - #{Faker::Name.first_name}",
		'type' => 'PhoneCall',
		'cssi_disposition' => 'Appointment Set'
	};
	fake_data
end

def get_fake_appointment_data(opportunity_id, due_offset_hours=1)
	offset_seconds = (due_offset_hours.to_f * 60 * 60)
	length_seconds = (60 * 30)
	fake_data = {
		'regardingobjectid' => {'type' => 'opportunity', 'id' => opportunity_id},
		'subject' => 'Test Appointment',
		'scheduledstart' => format_date_time(Time.now + offset_seconds),
		'scheduledend' => format_date_time(Time.now + offset_seconds + length_seconds),
		'type' => 'Appointment',
		'statecode' => 'Scheduled',
		'statuscode' => 'Busy'
	}
	fake_data
end

def get_fake_note_data(object_id, object_type)
	fake_data = {
		'subject' => Faker::Lorem.words.join(' '),
		'objectid' => {'id' => object_id},
		'objecttypecode' => object_type,
		'notetext' => Faker::Lorem.sentences.join(' ')
	}
	fake_data
end

def format_date_time(dateTime)
	formattedDateTime = ''
	if dateTime.kind_of? Date then
		formattedDateTime = dateTime.strftime("%Y/%m/%d")
	elsif dateTime.kind_of? Time then
		formattedDateTime = dateTime.strftime("%Y/%m/%d %H:%M:%S")
	end
	formattedDateTime
end

def days_to_seconds(days)
	days.to_f * 24 * 60 * 60
end

def hours_to_seconds(hours)
	hours.to_f * 60 * 60
end

def get_crm_appointment_time_hash(startTime, endTime)
	{
		'scheduledstart' => format_date_time(startTime),
		'scheduledend' => format_date_time(endTime)
	}
end

def create_contact(server,token,identity,additional_attributes=nil)
	contact_data = get_fake_contact_data(identity)
	contact_data.merge!(additional_attributes) unless additional_attributes.nil?
	ap contact_data
	id = RestClient.post("#{server}/contact/create", { :token => token, :attributes => contact_data.to_json }).body
	ap id
	id
end

def create_opportunity(server,token,contact_id,identity,additional_attributes=nil)
	opportunity_data = get_fake_opportunity_data(contact_id, identity)
	opportunity_data.merge!(additional_attributes) unless additional_attributes.nil?
	ap opportunity_data
	id = RestClient.post("#{server}/opportunity/create", { :token => token, :attributes => opportunity_data.to_json }).body
	ap id
	id
end

def create_phonecall(server,token,opportunity_id,additional_attributes=nil)
	phonecall_data = get_fake_phonecall_data(opportunity_id)
	phonecall_data.merge!(additional_attributes) unless additional_attributes.nil?
	ap phonecall_data
	id = RestClient.post("#{server}/activity/create", { :token => token, :attributes => phonecall_data.to_json }).body
	ap id
	id
end

def update_phonecall(server,token,phonecall_id,attributes)
	if attributes.nil? then
		throw :attributes_must_be_specified
	end
	
	attributes.merge!({
		'type' => 'PhoneCall',
		'activityid' => phonecall_id
	})
	
	RestClient.post("#{server}/activity/udate", { :token => token, :attributes => attributes.to_json }).body
end

def create_appointment(server,token,opportunity_id,additional_attributes=nil)
	appointment_data = get_fake_appointment_data(opportunity_id)
	appointment_data.merge!(additional_attributes) unless additional_attributes.nil?
	ap appointment_data
	id = RestClient.post("#{server}/activity/create", { :token => token, :attributes => appointment_data.to_json }).body
	ap id
	id
end

def create_note(server,token,object_id, object_type,additional_attributes=nil)
	note_data = get_fake_note_data(object_id, object_type)
	note_data.merge!(additional_attributes) unless additional_attributes.nil?
	ap note_data
	id = RestClient.post("#{server}/annotation/create", { :token => token, :attributes => note_data.to_json }).body
	ap id
	id
end

def update_appointment(server,token,appointment_id,attributes)
	if attributes.nil? then
		throw :attributes_must_be_specified
	end
	
	attributes.merge!({
		'type' => 'Appointment',
		'activityid' => appointment_id
	})
	
	RestClient.post("#{server}/activity/udate", { :token => token, :attributes => attributes.to_json }).body
end

#----------------------------

def generate_new_contacts(server,token,identity,contact_count,additional_attributes=nil,create_notes=false)
	puts "Generating #{contact_count} new contacts"
	created_contact_ids = []
	for i in 1..contact_count
		created_contact_ids.push(create_contact(server, token, identity, additional_attributes))
	end
	generate_new_notes(server,token,created_contact_ids,'contact') if create_notes
	created_contact_ids
end

def generate_new_opportunities(server,token,identity,contact_ids,additional_attributes=nil,create_notes=false)
	puts "Generating #{contact_ids.count} new opportunities"
	created_opportunity_ids = []
	contact_ids.each { |contact_id|
		created_opportunity_ids.push(create_opportunity(server, token, contact_id, identity, additional_attributes))
	}
	generate_new_notes(server,token,created_opportunity_ids,'opportunity') if create_notes
	created_opportunity_ids
end

def generate_new_phonecalls(server,token,opportunity_ids,additional_attributes=nil,create_notes=false)
	puts "Generating #{opportunity_ids.count} new phonecalls"
	created_phonecall_ids = []
	opportunity_ids.each { |opportunity_id|
		created_phonecall_ids.push(create_phonecall(server, token, opportunity_id, additional_attributes))
	}
	generate_new_notes(server,token,created_phonecall_ids,'phonecall') if create_notes
	created_phonecall_ids
end

def generate_new_appointments(server,token,opportunity_ids,additional_attributes=nil,create_notes=false)
	puts "Generating #{opportunity_ids.count} new appointments"
	created_appointment_ids = []
	opportunity_ids.each { |opportunity_id|
		created_appointment_ids.push(create_appointment(server, token, opportunity_id, additional_attributes))
	}
	generate_new_notes(server,token,created_appointment_ids,'appointment') if create_notes
	created_appointment_ids
end

def generate_new_notes(server,token,object_ids,object_type,additional_attributes=nil)
	puts "Generating #{object_ids.count} new notes"
	object_ids.map {|objectId| create_note(server,token,objectId,object_type,additional_attributes)}
end

#-----------------------

def generate_leads_with_phonecall(server,token,identity,lead_count,phonecall_attributes=nil,create_notes=false)
	puts "Generating #{lead_count} new leads with phone calls"
	created_lead_ids = generate_new_leads(server,token,identity,lead_count,nil,create_notes)
	created_phonecall_ids = generate_new_phonecalls(server,token,created_lead_ids,phonecall_attributes,create_notes)
end

def generate_leads_with_appointment(server,token,identity,lead_count,appointment_attributes=nil,create_notes=false)
	puts "Generating #{lead_count} new leads with appointments"
	created_lead_ids = generate_new_leads(server,token,identity,lead_count,nil,create_notes)
	created_appointment_ids = generate_new_appointments(server,token,created_lead_ids,appointment_attributes,create_notes)
	
end

#-----------------------

def generate_new_leads(server,token,identity,lead_count,created_seconds_ago=nil,create_notes=false)
	puts "Generating #{lead_count} new leads, created #{created_seconds_ago} seconds ago"
	override_created_on = created_seconds_ago.nil? ? {} : {
		'overriddencreatedon' => format_date_time(Time.now - created_seconds_ago)
	}
	created_contact_ids = generate_new_contacts(server,token,identity,lead_count,nil,create_notes)
	created_opportunity_ids = generate_new_opportunities(server,token,identity,created_contact_ids,override_created_on,create_notes)
	created_opportunity_ids
end

def generate_new_leads_for_contact(server,token,identity,lead_count,contact_id,created_seconds_ago=nil,create_notes=false)
	puts "Generating #{lead_count} new leads for contact #{contact_id}, created #{created_seconds_ago} seconds ago"
	override_created_on = created_seconds_ago.nil? ? {} : {
		'overriddencreatedon' => format_date_time(Time.now - created_seconds_ago)
	}
	created_opportunity_ids = []
	for i in 1..lead_count
		created_opportunity_ids.push(create_opportunity(server, token, contact_id, identity, override_created_on))
	end
	generate_new_notes(server,token,created_opportunity_ids,'opportunity') if create_notes
	created_opportunity_ids
end

def generate_followup_leads(server,token,identity,lead_count,due_seconds=nil,create_notes=false)
	puts "Generating #{lead_count} new phonecalls, due #{due_seconds} seconds from now"
	phonecall_attributes = due_seconds.nil? ? {} : {
		'scheduledend' => format_date_time(Time.now + due_seconds)
	}
	generate_leads_with_phonecall(server,token,identity,lead_count,phonecall_attributes,create_notes)
end

def generate_stale_leads(server,token,identity,lead_count,create_notes=false)
	puts "Generating #{lead_count} closed phonecalls"
	phonecall_attributes = {
		'statecode' => 'Completed',
		'cssi_disposition' => 'No Answer'
	}
	generate_leads_with_phonecall(server,token,identity,lead_count,phonecall_attributes,create_notes)
end

def generate_appointment_leads(server,token,identity,lead_count,due_seconds=nil,create_notes=false)
	puts "Generating #{lead_count} leads with appointments due in #{due_seconds} seconds"
	dueStartTime = (Time.now + (due_seconds || 0))
	dueEndTime = (dueStartTime + (60 * 30))
	appointment_attributes = get_crm_appointment_time_hash(dueStartTime, dueEndTime)
	ap appointment_attributes
	generate_leads_with_appointment(server,token,identity,lead_count,appointment_attributes,create_notes)
end