require 'ap'

$tokenfile = '.proxy_token'
$environmentfile = '.environment'
$identityfile = '.overridden_identity'

$create_notes = false

$environments = {'local' => 'http://localhost:52904', 
  'dev-internal' => 'http://nrhwwwd401.insp.dom:5000', 
  'dev-external' => 'http://75.31.122.27', 
  'model-internal' => 'http://nrhwwwm201.insp.dom:5000', 
  'model-external' => 'https://mobileproxy.model.insphereis.net'}

namespace :proxy do
    desc "Generates [lead_count] new leads, [age] days old"
    task :populate_newleads, [:lead_count,:age] => [:setup, :set_identity] do |t,args|
		lead_count = args[:lead_count].nil? ? 1 : args[:lead_count].to_i
		age_seconds = args[:age].nil? ? nil : days_to_seconds(args[:age])
		generate_new_leads(@proxy_url,@token,@identity,lead_count.to_i,age_seconds,$create_notes)
    end
	
	desc "Generates [lead_count] followup leads, due [due] days from now"
	task :populate_followupleads, [:lead_count,:due] => [:setup, :set_identity] do |t,args|
		due_seconds = args[:due].nil? ? 0 : days_to_seconds(args[:due])
		lead_count = args.lead_count.nil? ? 1 : args.lead_count.to_i
		generate_followup_leads(@proxy_url,@token,@identity,lead_count,due_seconds,$create_notes)
	end
	
	desc "Generates [lead_count] appointment leads, due [due] days from now"
	task :populate_appointmentleads, [:lead_count,:due] => [:setup, :set_identity] do |t,args|
		due_seconds = args[:due].nil? ? nil : days_to_seconds(args[:due])
		lead_count = args[:lead_count].nil? ? 1 : args[:lead_count].to_i
		generate_appointment_leads(@proxy_url,@token,@identity,lead_count,due_seconds,$create_notes)
	end
	
	desc "Generates [lead_count] stale leads (i.e. has activities but none are open)"
	task :populate_staleleads, [:lead_count] => [:setup, :set_identity] do |t,args|
		lead_count = args[:lead_count].nil? ? 1 : args[:lead_count].to_i
		generate_stale_leads(@proxy_url,@token,@identity,lead_count,$create_notes)
	end
	
	desc "Generates [lead_count] new leads, [age] days old, and associates them to contact with id [contact_id]"
	task :populate_newleads_forcontact, [:lead_count,:age,:contact_id] => [:setup, :set_identity] do |t,args|
		lead_count = args[:lead_count].nil? ? 1 : args[:lead_count].to_i
		age_seconds = args[:age].nil? ? nil : days_to_seconds(args[:age])
		contact_id = args[:contact_id]
		generate_new_leads_for_contact(@proxy_url,@token,@identity,lead_count,contact_id,age_seconds)
	end
	
	desc "Generates a full dataset, with [lead_count] leads in each bin (today, future, etc.) of each category (new leads, follow ups, appointments)"
	task :populate_full_dataset, [:lead_count] => [:setup, :set_identity] do |t,args|
		lead_count = args[:lead_count].nil? ? 1 : args[:lead_count].to_i
		future_seconds = days_to_seconds(10)
		today_seconds = 0
		past_seconds = days_to_seconds(-1)
		#generate new leads in today and previous days buckets
		generate_new_leads(@proxy_url,@token,@identity,lead_count,today_seconds,$create_notes)
		generate_new_leads(@proxy_url,@token,@identity,lead_count,-past_seconds,$create_notes)
		#generate followups in past due, today, and future buckets
		generate_followup_leads(@proxy_url,@token,@identity,lead_count,past_seconds,$create_notes)
		generate_followup_leads(@proxy_url,@token,@identity,lead_count,today_seconds,$create_notes)
		generate_followup_leads(@proxy_url,@token,@identity,lead_count,future_seconds,$create_notes)
		#generate followups in "by last activity" bucket
		generate_stale_leads(@proxy_url,@token,@identity,lead_count,$create_notes)
		#generate appointments in past due, today, and future buckets
		generate_appointment_leads(@proxy_url,@token,@identity,lead_count,past_seconds,$create_notes)
		generate_appointment_leads(@proxy_url,@token,@identity,lead_count,today_seconds,$create_notes)
		generate_appointment_leads(@proxy_url,@token,@identity,lead_count,future_seconds,$create_notes)
	end
	
	desc "Generates [contact_count] new contacts"
	task :populate_contacts, [:contact_count] => [:setup, :set_identity] do |t,args|
		contact_count = args[:contact_count].nil? ? 1 : args[:contact_count].to_i
		generate_new_contacts(@proxy_url,@token,@identity,contact_count,nil,$create_notes)
	end
	
	task :set_identity => :setup do
		if File.exists?($identityfile)
			@identity = JSON.parse(File.readlines($identityfile).first.strip)
			puts 'Using overidden identity'
			ap @identity
		else
			@identity = who_am_i(@proxy_url, @token)
		end
	end
	
	task :override_identity, [:login_username,:login_password] => :setup do |t,args|
		abort "Error: username & password must be specified" if (args[:login_username].nil? or args[:login_password].nil?)
		username = args[:login_username]
		password = args[:login_password]
		puts "Logging in as #{username}"
		token = get_token(@proxy_url, username, password)
		identity = who_am_i(@proxy_url, token)
		logout(@proxy_url, token) #this is a throwaway, only used to get the user id corresponding to the overridden identity
		persist_to_file($identityfile, identity.to_json)
		ap "Got identity: #{identity['id']}"
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
		@fetched_entities = get_entities(@proxy_url, @token, args[:model_name])
		@fetched_entities = @fetched_entities.last(args[:max_count].to_i) if args[:max_count]
		ap @fetched_entities
	end
	
	task :get_entities_json, [:model_name, :max_count] => :setup do |t,args|
		@fetched_entities = get_entities(@proxy_url, @token, args[:model_name])
		@fetched_entities = @fetched_entities.last(args[:max_count].to_i) if args[:max_count]
		ap @fetched_entities.to_json
	end
	
	desc "Counts entities of type [:model_name]"
	task :count_entities, [:model_name] => :setup do |t,args|
		puts "#{args[:model_name]} count: #{get_entities(@proxy_url, @token, args[:model_name]).count}"
	end
	
	desc "Gets the last [:line_count] lines of the proxy logs; use a line_count of 0 to get all lines, proxy defaults to 50 lines"
	task :get_logs, [:line_count] => :setup do |t,args|
		puts get_log(@proxy_url, @token, args[:line_count])
	end
	
	desc "Log in to the proxy with username [:login_username] and password [:login_password]"
	task :login, [:login_username,:login_password] => [:get_proxy_url, :clear_persisted_token] do |t,args|
		abort "Error: username & password must be specified" if (args[:login_username].nil? or args[:login_password].nil?)
		username = args[:login_username]
		password = args[:login_password]
		puts "Logging in as #{username}"
		@token = get_token(@proxy_url, username, password)
		persist_to_file($tokenfile, @token)
		puts "Logged in, new token: #{@token}"
	end
	
	task :logout => [:clear_persisted_token] do
		puts "Logged out"
	end
	
	task :setup => [:get_proxy_url, :get_persisted_token]
	
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
	
	desc "Gets the persisted proxy token"
	task :get_persisted_token do
		if File.exists?($tokenfile)
			@token = File.readlines($tokenfile).first.strip
			puts "using persisted token starting with #{@token[0,6]}..."
		else
			abort "no persisted token found, authenticate using login task..."
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

	task :clear_persisted_token do
		remove_file_if_exists($tokenfile)
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