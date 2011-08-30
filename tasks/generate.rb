
$credentialfile = '.proxy_credential'
$environmentfile = '.environment'
$identityfile = '.overridden_identity'

$create_notes = false

$environments = {'local' => 'http://192.168.51.128', 
  'dev-internal' => 'http://nrhwwwd401.insp.dom:5000', 
  'dev-external' => 'https://devmobileproxy.insphereis.net', 
  'model-external' => 'https://mobileproxy.model.insphereis.net',
  'production-external' => 'https://mobileproxy.insphereis.net',
  'dev-integrated' => 'http://nrhwwwd403.insp.dom:2195/crm/ActivityCenter/MobileProxy'}

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

  $lead_sources = ['Internet','Direct Mail','E-Mail','Newspaper','Other','PDL','Radio','Referral']

  $lead_vendors = ['AllWeb','Humana','InsureMe','iPipeline','Most Choice']

  $lead_types = ['Agent Website','Banner','Classified','Other','Search']


namespace :generate do
  
  def get_fake_contact_data(identity)
  	preferred_phone = ['Home','Mobile','Business'][rand(3)]

    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    email = "#{first_name}.#{last_name}@fakegendatacrm.net"

  	fake_data = {
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
  		'ownerid' => {'type' => 'systemuser', 'id' => identity['id']},
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
  
  def get_fake_opportunity_data(contact_id, identity)
  	fake_data = {
  		'contact_id' => contact_id,
  		'cssi_leadsourceid' => rand_array_item($lead_sources),
  		'cssi_leadvendorid' => rand_array_item($lead_vendors),
  		'cssi_leadtypeid' => rand_array_item($lead_types),
  		'ownerid' => {'type' => 'systemuser', 'id' => identity['id']},
  		'cssi_inputsource' => 'Integrated'
  	};
  	fake_data
  end
  
  def get_fake_activity_data_in_scope_case1(activity_type,identity_id,type,due_offset_hours=4)
      #case 1 , Completed, <14 days old
    	offset_seconds = (due_offset_hours.to_f * 60 * 60)
    	length_seconds = (60 * 30)
      regarding = {'type' => type, 'id' => identity_id} unless identity_id.nil?
    	fake_data = {
      	'regardingobjectid' => regarding,
    		'subject' => "Test #{activity_type}",
    		'scheduledstart' => format_date_time(Time.now + offset_seconds),
    		'scheduledend' => format_date_time(Time.now + offset_seconds + length_seconds),
    		'type' => activity_type,
    		'statecode' => 'Completed',
    	}
    	fake_data
  end
  def get_fake_activity_data_in_scope_case2(activity_type,identity_id,type,due_offset_hours=4)
        #case 1 , Open, < 60 days old
      	offset_seconds = (due_offset_hours.to_f * 60 * 60)
      	length_seconds = (60 * 30)
        regarding = {'type' => type, 'id' => identity_id} unless identity_id.nil?
      	fake_data = {
        	'regardingobjectid' => regarding,
      		'subject' => "Test #{activity_type}",
      		'scheduledstart' => format_date_time(Time.now + offset_seconds),
      		'scheduledend' => format_date_time(Time.now + offset_seconds + length_seconds),
      		'type' => activity_type,
      		'statecode' => 'Open',
      	}
      	fake_data
  end
  def get_fake_activity_data_in_scope_case3(activity_type,identity_id,type,due_offset_hours=4)
          #case 3 , Open, < 60 days old, scheduledend is null
        	offset_seconds = (due_offset_hours.to_f * 60 * 60)
        	length_seconds = (60 * 30)
          regarding = {'type' => type, 'id' => identity_id} unless identity_id.nil?
        	fake_data = {
          	'regardingobjectid' => regarding,
        		'subject' => "Test #{activity_type}",
        		'scheduledstart' => format_date_time(Time.now + offset_seconds),
        		'scheduledend' => nil,
        		'type' => activity_type,
        		'statecode' => 'Open',
        	}
        	fake_data
  end

  def get_fake_activity_data_out_of_scope_case1(activity_type,identity_id,type,due_offset_hours=4)
      #case 1 , Completed, >14 days old
    	offset_seconds = (65 * 24 * 60 * 60)
    	length_seconds = (60 * 30)
      regarding = {'type' => type, 'id' => identity_id} unless identity_id.nil?
    	fake_data = {
      	'regardingobjectid' => regarding,
    		'subject' => "Test #{activity_type}",
    		'scheduledstart' => format_date_time(Time.now - offset_seconds),
    		'scheduledend' => format_date_time(Time.now - offset_seconds + length_seconds),
    		'actualend' => format_date_time(Time.now - offset_seconds + length_seconds),
    		'type' => activity_type,
    		'statecode' => 'Completed',
    	}
    	fake_data
  end
  def get_fake_activity_data_out_of_scope_case2(activity_type,identity_id,type,due_offset_hours=4)
        #case 1 , Open, < 60 days old
      	offset_seconds = (65 * 24 * 60 * 60)
      	length_seconds = (60 * 30)
        regarding = {'type' => type, 'id' => identity_id} unless identity_id.nil?
      	fake_data = {
        	'regardingobjectid' => regarding,
      		'subject' => "Test #{activity_type}",
      		'scheduledstart' => format_date_time(Time.now - offset_seconds),
      		'scheduledend' => format_date_time(Time.now - offset_seconds + length_seconds),
      		'type' => activity_type,
      		'statecode' => 'Open',
      	}
      	fake_data
  end
  def get_fake_activity_data_out_of_scope_case3(activity_type,identity_id,type,due_offset_hours=4)
          #case 3 , Open, > 60 days old, scheduledend is null
        	offset_seconds = (65 * 24 * 60 * 60)
          regarding = {'type' => type, 'id' => identity_id} unless identity_id.nil?
        	fake_data = {
          	'regardingobjectid' => regarding,
        		'subject' => "Test #{activity_type}",
        		'scheduledstart' => format_date_time(Time.now - offset_seconds),
        		'scheduledend' => nil,
        		'type' => activity_type,
        		'statecode' => 'Open',
        	}
        	fake_data
  end

    
  def get1_fake_appointment_data(in_scope,identity_id,type,due_offset_hours=1)
  	offset_seconds = (due_offset_hours.to_f * 60 * 60)
  	length_seconds = (60 * 30)
    regarding = {'type' => type, 'id' => identity_id} unless identity_id.nil?
  	fake_data = {
    	'regardingobjectid' => regarding,
  		'subject' => 'Test Appointment',
  		'scheduledstart' => format_date_time(Time.now + offset_seconds),
  		'scheduledend' => format_date_time(Time.now + offset_seconds + length_seconds),
  		'type' => 'Appointment',
  		'statecode' => 'Scheduled',
  		'statuscode' => 'Busy'
  	}
  	fake_data
  end

  def get1_fake_phonecall_data(in_scope,identity_id,type)
    regarding = {'type' => type, 'id' => identity_id} unless identity_id.nil?
  	fake_data = {
  		'regardingobjectid' => regarding,
  		'subject' => "Test Phone Call - #{Faker::Name.first_name}",
  		'type' => 'PhoneCall',
  		'phonenumber' => "#{Faker::PhoneNumber.phone_number}",
  		'cssi_phonetype' => "Home",
  		'statecode' => rand_activity_state
  	};
  	fake_data
  end

  def get1_fake_task_data(in_scope,identity_id,type)
    regarding = {'type' => type, 'id' => identity_id} unless identity_id.nil?
  	fake_data = {
  		'regardingobjectid' => regarding,
  		'scheduledstart' => format_date_time(Time.now + 1000),
  		'subject' => "Test Task Data",
  		'type' => 'Task',
  		'description' => "Test Description",
  		'statecode' => rand_activity_state
  	};
  	fake_data
  end

  def generate1_new_notes(server,credential,object_ids,object_type,additional_attributes=nil)
  	puts "Generating #{object_ids.count} new notes"
  	object_ids.map {|objectId| create_note(server,credential,objectId,object_type,additional_attributes)}
  end

  def create_in_scope_activities(activity_type,server,credential,regarding_identity_id=nil,regarding_type=nil)
    puts "Generating Fake Appointment Data"
  	created_ids = []
    fake_data = get_fake_activity_data_in_scope_case1(activity_type,regarding_identity_id,regarding_type) 
    created_ids.push(create_fake_activity(fake_data, server, credential))
    fake_data = get_fake_activity_data_in_scope_case2(activity_type,regarding_identity_id,regarding_type) 
    created_ids.push(create_fake_activity(fake_data, server, credential))
    fake_data = get_fake_activity_data_in_scope_case3(activity_type,regarding_identity_id,regarding_type) 
    created_ids.push(create_fake_activity(fake_data, server, credential))
    created_ids
  end
  def create_out_of_scope_activities(activity_type,server,credential,regarding_identity_id=nil,regarding_type=nil)
    puts "Generating Fake Appointment Data"
  	created_ids = []
    fake_data = get_fake_activity_data_out_of_scope_case1(activity_type,regarding_identity_id,regarding_type) 
    created_ids.push(create_fake_activity(fake_data, server, credential))
    fake_data = get_fake_activity_data_out_of_scope_case2(activity_type,regarding_identity_id,regarding_type) 
    created_ids.push(create_fake_activity(fake_data, server, credential))
    fake_data = get_fake_activity_data_out_of_scope_case3(activity_type,regarding_identity_id,regarding_type) 
    created_ids.push(create_fake_activity(fake_data, server, credential))
    created_ids
  end

  def create_fake_activity(fake_data, server, credential)
  	ap fake_data
  	puts fake_data.inspect 
  	id = RestClient.post("#{server}/activity/create", credential.to_hash.merge(:attributes => fake_data.to_json)).body
  	ap id
  	id
  end

  def create_contact(server,credential,identity,additional_attributes=nil)
  	contact_data = get_fake_contact_data(identity)
  	contact_data.merge!(additional_attributes) unless additional_attributes.nil?
  	ap contact_data
  	id = RestClient.post("#{server}/contact/create", credential.to_hash.merge(:attributes => contact_data.to_json)).body
  	ap id
  	id
  end

  def create_policy(server,credential,identity,contact_id,policy_status)
    policy_data = get_fake_policy_data(identity,policy_status)
    policy_data.merge!({'cssi_contactid' => {'type' => 'contact', 'id' => contact_id}})
    ap policy_data
    policy_id = RestClient.post("#{server}/policy/create", credential.to_hash.merge(:attributes => policy_data.to_json)).body
    ap policy_id
    policy_id
  end

  def create_opportunity(server,credential,contact_id,identity,additional_attributes=nil)
  	opportunity_data = get_fake_opportunity_data(contact_id, identity)
  	opportunity_data.merge!(additional_attributes) unless additional_attributes.nil?
  	ap opportunity_data
  	id = RestClient.post("#{server}/opportunity/create", credential.to_hash.merge(:attributes => opportunity_data.to_json)).body
  	ap id
  	id
  end


  def create_opportunity_and_activities(server,credential)
    
    contact_id = create_contact(server,credential,@identity)
    opportunity_id = create_opportunity(server,credential,contact_id,@identity)

    create_in_scope_activities('Appointment',server,credential,contact_id,"Contact") 
    create_in_scope_activities('Task',server,credential,contact_id,"Contact") 
    create_in_scope_activities('PhoneCall',server,credential,contact_id,"Contact")
    
    puts "Creating Oportunity Activities"
    
    create_in_scope_activities('Appointment',server,credential,opportunity_id,"Opportunity") 
    create_in_scope_activities('Task',server,credential,opportunity_id,"Opportunity") 
    create_in_scope_activities('PhoneCall',server,credential,opportunity_id,"Opportunity")
    
  end

  def create_policy_and_activities(server,credential)
    
    contact_id = create_contact(server,credential,@identity)
    policy_id = create_policy(server,credential,@identity,contact_id,'Active')

    create_in_scope_activities('Appointment',server,credential,contact_id,"Contact") 
    create_in_scope_activities('Task',server,credential,contact_id,"Contact") 
    create_in_scope_activities('PhoneCall',server,credential,contact_id,"Contact")
    
    puts "Creating policy Activities"
    
    create_in_scope_activities('Appointment',server,credential,policy_id,"Policy") 
    create_in_scope_activities('Task',server,credential,policy_id,"Policy") 
    create_in_scope_activities('PhoneCall',server,credential,policy_id,"Policy")
    
  end

  desc "Generates a number of opportunities and activities with these"
  task :create_opportunity_with_activities, [:opportunity_count] => [:setup, :set_identity] do |t,args|
    opportunity_count = args[:opportunity_count].nil? ? 1 : args[:opportunity_count].to_i
    
    
    opportunity_ids = []
    
    opportunity_count.times do 
      opportunity_ids.push(create_opportunity_and_activities(@proxy_url,@credential))
    end 
    
    puts opportunity_ids.inspect
  end


  desc "Generates a number of policies and activities with these"
  task :create_policy_with_activities, [:policy_count] => [:setup, :set_identity] do |t,args|
    policy_count = args[:policy_count].nil? ? 1 : args[:policy_count].to_i
    
    
    policy_ids = []
    
    policy_count.times do 
      policy_ids.push(create_policy_and_activities(@proxy_url,@credential))
    end 
    
    puts policy_ids.inspect
  end

  
  desc "Generates inscope and out of scope activities"
  task :populate_standaloneactivities, [:in_scope] => [:setup, :set_identity] do |t,args|
    in_scope = args[:in_scope].nil? ? true : args[:in_scope].downcase! == 'true' ? true:false
    
      puts in_scope
    activity_ids = []
    
    in_scope ? activity_ids.push(create_in_scope_activities('Appointment',@proxy_url,@credential)) : activity_ids.push(create_out_of_scope_activities('Appointment',@proxy_url,@credential))
    in_scope ? activity_ids.push(create_in_scope_activities('Task',@proxy_url,@credential)) : activity_ids.push(create_out_of_scope_activities('Task',@proxy_url,@credential))
    in_scope ? activity_ids.push(create_in_scope_activities('PhoneCall',@proxy_url,@credential)) : activity_ids.push(create_out_of_scope_activities('PhoneCall',@proxy_url,@credential))
    
    puts activity_ids.inspect
  end
  	
  	
  	
	task :set_identity => :setup do
		if File.exists?($identityfile)
			@identity = JSON.parse(File.readlines($identityfile).first.strip)
			puts 'Using overidden identity'
			ap @identity
		else
			@identity = who_am_i(@proxy_url, @credential)
		end
	end
	
	desc "Override the identity that is used to talk to CRM; this allows you to create data on another user's behalf"
	task :override_identity, [:login_username,:login_password] => :setup do |t,args|
		abort "Error: username & password must be specified" if (args[:login_username].nil? or args[:login_password].nil?)
		username = args[:login_username]
		password = args[:login_password]
		credential = Credential.new(username, password)
		puts "Logging in as #{username}"
		identity = who_am_i(@proxy_url, credential)
		persist_to_file($identityfile, identity.to_json)
		ap "Got identity: #{identity['id']}"
	end
	
	desc "Override the identity that is used to talk to CRM; this allows you to create data on another user's behalf"
	task :override_identity_direct, [:username, :user_id] => :setup do |t,args|
		abort "Error: username & user ID must be specified" if (args[:username].nil? or args[:user_id].nil?)
		override_identity = {"id" => args[:user_id], "user_name" => args[:username]}
		persist_to_file($identityfile, override_identity.to_json)
		ap "Successfully set override identity #{override_identity['id']}"
	end
	
	desc "Clears the overridden identity"
	task :clear_override_identity do
		remove_file_if_exists($identityfile)
	end
	
	desc "Shows information about the currently logged in user"
	task :show_identity => :set_identity do
		ap @identity
	end
	
	desc "Gets all entities of type [:model_name], caps to last [:max_count] entities if specified"
	task :get_entities, [:model_name, :max_count] => :setup do |t,args|
		@fetched_entities = get_entities(@proxy_url, @credential, args[:model_name])
		@fetched_entities = @fetched_entities.last(args[:max_count].to_i) if args[:max_count]
		ap @fetched_entities
	end
	
	task :get_entities_json, [:model_name, :max_count] => :setup do |t,args|
		@fetched_entities = get_entities(@proxy_url, @credential, args[:model_name])
		@fetched_entities = @fetched_entities.last(args[:max_count].to_i) if args[:max_count]
		ap @fetched_entities.to_json
	end
	
	desc "Counts entities of type [:model_name]"
	task :count_entities, [:model_name] => :setup do |t,args|
		puts "#{args[:model_name]} count: #{get_entities(@proxy_url, @credential, args[:model_name]).count}"
	end
	
	desc "Gets the last [:line_count] lines of the proxy logs; use a line_count of 0 to get all lines, proxy defaults to 50 lines"
	task :get_logs, [:line_count] => :setup do |t,args|
		puts get_log(@proxy_url, @credential, args[:line_count])
	end
	
	desc "Log in to the proxy with username [:login_username] and password [:login_password]"
	task :login, [:login_username,:login_password] => [:get_proxy_url, :clear_persisted_credential] do |t,args|
		abort "Error: username & password must be specified" if (args[:login_username].nil? or args[:login_password].nil?)
		username = args[:login_username]
		password = args[:login_password]
		puts "Logging in as #{username}"
		begin
		  login(@proxy_url, username, password)
		  @credential = Credential.new(username, password)
		  persist_to_file($credentialfile, @credential.to_string)
  		puts "Logged in successfully"
		rescue
		  puts "Login failed"
	  end
	end
	
	task :setup => [:get_proxy_url, :get_persisted_credential]
	
	desc "Gets the proxy URL corresponding to the persisted environment"
	task :get_proxy_url => [:get_persisted_environment] do
		@proxy_url = $environments[@environment]
		puts "Targeting #{@environment} => #{@proxy_url}"
	end
	
	task :get_persisted_environment do
		if File.exists?($environmentfile)
			@environment = File.readlines($environmentfile).first.strip
		else
			abort "environment has not yet been defined; run proxy:set_environment..."
		end
	end
	
	desc "Gets the persisted proxy credential"
	task :get_persisted_credential do
		if File.exists?($credentialfile)
			@credential = Credential.from_string(File.readlines($credentialfile).first.strip)
			puts "using persisted credential for user #{@credential.username}..."
		else
			abort "no persisted credential found, authenticate using login task..."
		end
	end
	
	desc "Sets & persists the environment targeted by subsequent tasks"
	task :set_environment, [:environment] => :clear_persisted_environment do |t,args|
		unless $environments.include?(args[:environment])
			if(args[:environment].nil?)
				puts "Please specify an environment; choices are:"
			else
				puts "Invalid environment #{args[:environment]}; valid choices are:"
			end
			ap $environments
			abort
		end
		@environment = args[:environment]
		@proxy_url = $environments[@environment]
		persist_to_file($environmentfile, args[:environment])
		puts "Set environment to #{args[:environment]} => #{@proxy_url}"
	end

	task :clear_persisted_credential do
		remove_file_if_exists($credentialfile)
	end
	
	task :clear_persisted_environment do
		remove_file_if_exists($environmentfile)
	end
	
	def persist_to_file(filepath, data)
		File.open(filepath, 'w') {|f| f.write(data) }
	end
	
	def remove_file_if_exists(filepath)
		File.delete(filepath) if File.exists?(filepath)
	end
end