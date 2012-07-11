
$credentialfile = '.proxy_credential'
$environmentfile = '.environment'
$identityfile = '.overridden_identity'

$create_notes = false

$environments = {'local' => 'http://192.168.51.128', 
  'dev-internal' => 'http://nrhwwwd403.insp.dom:5000', 
  'dev-external' => 'https://mobileproxy.dev.insphereis.net', 
  'model-external' => 'https://mobileproxy.model.insphereis.net',
  'production-external' => 'https://mobileproxy.insphereis.net',
  'dev-integrated' => 'http://nrhwwwd403.insp.dom:2195/crm/ActivityCenter/MobileProxy',
  'local' => 'IT-64VANDEVENTE:49938' }

namespace :proxy do
  def rest_rescue
    begin
      yield if block_given?
    rescue RestClient::Exception => e
      puts "Got rest exception:"
      ap e
    end
  end
  
  task :populate_phonecalls_for_opp, [:opp_id, :phonecall_count] => [:setup, :set_identity] do |t,args|
    (0...args[:phonecall_count].to_i).each do
      create_phonecall(@proxy_url,@credential,args[:opp_id])
    end
  end
  
  task :populate_notes_for_opp, [:opp_id, :note_count] => [:setup, :set_identity] do |t,args|
    rest_rescue do
      (0...args[:note_count].to_i).each do
        create_note(@proxy_url,@credential,args[:opp_id],'opportunity')
      end
    end
  end
  
  desc "Generates [policy_count] new policies and contacts.  If status is passed in, it will use the status; otherwise active"
  task :populate_newpolicies, [:policy_count,:status] => [:setup, :set_identity] do |t,args|
    policy_count = args[:policy_count].nil? ? 1 : args[:policy_count].to_i
    policy_status = args[:status].nil? ? 'Active' : args[:status]
    populate_new_policies(@proxy_url,@credential,@identity,policy_count,policy_status)
  end
  
  task :populate_policies_for_contact, [:contact_id,:policy_count,:status] => [:setup, :set_identity] do |t,args|
    abort "contact_id must be specified" unless args[:contact_id]
    policy_count = args[:policy_count].nil? ? 1 : args[:policy_count].to_i
    policy_status = args[:status].nil? ? 'Active' : args[:status]
    puts "Generating #{args[:policy_count]} new policies for contact #{args[:contact_id]}"
    (1..policy_count).each{ generate_new_policies(@proxy_url,@credential,@identity,[args[:contact_id]],policy_status) }
  end
  
  desc "Updates the [primary_insured] name of policy # [policy_id]"
  task :update_policy_primaryinsured, [:policy_id, :primary_insured] => [:setup, :set_identity] do |t,args|
    policy_id = args[:policy_id]
    primary_insured = args[:primary_insured]
    
    update_policy_primary_insured(@proxy_url,@credential,@identity,policy_id,primary_insured)
  end
  
  desc "Reassigns an opportunity"
  task :reassign_opportunity, [:opportunity_id,:reassignee_id] => [:setup, :set_identity] do |t,args|
    opportunity_id = args[:opportunity_id]
    reassignee_id = args[:reassignee_id]
    
    opportunity_reassign(@proxy_url,@credential,@identity,opportunity_id,reassignee_id)
  end
  
  desc "Deletes an activity in CRM given its GUID and activity type"
  task :delete_activity, [:activity_id,:activity_type] => [:setup, :set_identity] do |t,args|
    activity_id = args[:activity_id]
    activity_type = args[:activity_type]
    
    delete_activity_by_id(@proxy_url,@credential,@identity,activity_id,activity_type)
  end
  
  desc "Resets the DNC status of all numbers on [contact_id] back to allow calls."
  task :reset_contact_dncstatus, [:contact_id] => [:setup, :set_identity] do |t,args|
    contact_id = args[:contact_id]
    
    reset_contact_dnc_status(@proxy_url,@credential,@identity,contact_id)
  end
  
  desc "Generates [lead_count] new leads, [age] days old"
  task :populate_newleads, [:lead_count,:age] => [:setup, :set_identity] do |t,args|
    start = Time.now
		lead_count = args[:lead_count].nil? ? 1 : args[:lead_count].to_i
		age_seconds = args[:age].nil? ? nil : days_to_seconds(args[:age])
		generate_new_leads(@proxy_url,@credential,@identity,lead_count.to_i,age_seconds,$create_notes)
		puts "DONE IN: #{Time.now - start}s"
  end
	
	desc "Generates [lead_count] followup leads, due [due] days from now"
	task :populate_followupleads, [:lead_count,:due] => [:setup, :set_identity] do |t,args|
		due_seconds = args[:due].nil? ? 0 : days_to_seconds(args[:due])
		lead_count = args.lead_count.nil? ? 1 : args.lead_count.to_i
		generate_followup_leads(@proxy_url,@credential,@identity,lead_count,due_seconds,$create_notes)
	end
	
	desc "Generates [lead_count] appointment leads, due [due] days from now"
	task :populate_appointmentleads, [:lead_count,:due] => [:setup, :set_identity] do |t,args|
		due_seconds = args[:due].nil? ? nil : days_to_seconds(args[:due])
		lead_count = args[:lead_count].nil? ? 1 : args[:lead_count].to_i
		generate_appointment_leads(@proxy_url,@credential,@identity,lead_count,due_seconds,$create_notes)
	end
	
	desc "Generates [lead_count] stale leads (i.e. has activities but none are open)"
	task :populate_staleleads, [:lead_count] => [:setup, :set_identity] do |t,args|
		lead_count = args[:lead_count].nil? ? 1 : args[:lead_count].to_i
		generate_stale_leads(@proxy_url,@credential,@identity,lead_count,$create_notes)
	end
	
	desc "Generates [lead_count] new leads, [age] days old, and associates them to contact with id [contact_id]"
	task :populate_newleads_forcontact, [:lead_count,:age,:contact_id] => [:setup, :set_identity] do |t,args|
		lead_count = args[:lead_count].nil? ? 1 : args[:lead_count].to_i
		age_seconds = args[:age].nil? ? nil : days_to_seconds(args[:age])
		contact_id = args[:contact_id]
		generate_new_leads_for_contact(@proxy_url,@credential,@identity,lead_count,contact_id,age_seconds)
	end
	
	desc "Generates [dependent_count] new dependents and associates them to contact with id [contact_id]"
	task :populate_newdependents_forcontact, [:dependent_count,:contact_id] => [:setup, :set_identity] do |t,args|
	  dependent_count = args[:dependent_count].nil? ? 1 : args[:dependent_count].to_i
	  contact_id = args[:contact_id]
	  generate_new_dependents_for_contact(@proxy_url,@credential,@identity,dependent_count,contact_id)
  end
  
  desc "Deletes dependent with id [dependent_id]"
  task :delete_dependentid, [:dependent_id] => [:setup, :set_identity] do |t,args|
    dependent_id = args[:dependent_id]
    delete_dependent_by_id(@proxy_url,@credential,@identity,dependent_id)
  end
	
	desc "Generates a full dataset, with [lead_count] leads in each bin (today, future, etc.) of each category (new leads, follow ups, appointments)"
	task :populate_full_dataset, [:lead_count] => [:setup, :set_identity] do |t,args|
		lead_count = args[:lead_count].nil? ? 1 : args[:lead_count].to_i
		future_seconds = days_to_seconds(10)
		today_seconds = 0
		past_seconds = days_to_seconds(-1)
		#generate new leads in today and previous days buckets
		generate_new_leads(@proxy_url,@credential,@identity,lead_count,today_seconds,$create_notes)
		generate_new_leads(@proxy_url,@credential,@identity,lead_count,-past_seconds,$create_notes)
		#generate followups in past due, today, and future buckets
		generate_followup_leads(@proxy_url,@credential,@identity,lead_count,past_seconds,$create_notes)
		generate_followup_leads(@proxy_url,@credential,@identity,lead_count,today_seconds,$create_notes)
		generate_followup_leads(@proxy_url,@credential,@identity,lead_count,future_seconds,$create_notes)
		#generate followups in "by last activity" bucket
		generate_stale_leads(@proxy_url,@credential,@identity,lead_count,$create_notes)
		#generate appointments in past due, today, and future buckets
		generate_appointment_leads(@proxy_url,@credential,@identity,lead_count,past_seconds,$create_notes)
		generate_appointment_leads(@proxy_url,@credential,@identity,lead_count,today_seconds,$create_notes)
		generate_appointment_leads(@proxy_url,@credential,@identity,lead_count,future_seconds,$create_notes)
	end
	
	desc "Generates [contact_count] new contacts"
	task :populate_contacts, [:contact_count] => [:setup, :set_identity] do |t,args|
		contact_count = args[:contact_count].nil? ? 1 : args[:contact_count].to_i
		generate_new_contacts(@proxy_url,@credential,@identity,contact_count,nil,$create_notes)
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
		
		rest_rescue do
		  login(@proxy_url, username, password)
		  @credential = Credential.new(username, password)
		  persist_to_file($credentialfile, @credential.to_string)
  		puts "Logged in successfully"
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