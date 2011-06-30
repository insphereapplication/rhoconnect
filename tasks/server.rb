app_path = File.expand_path(File.join(File.dirname(__FILE__)) + '/..')
puts app_path
require "#{app_path}/util/config_file"

API_KEY = 'b8788d7b2ae404c9661f40215f5d9258aede9c83'

$settings_file = 'settings/settings.yml'
$settings = YAML::load_file($settings_file)
$target = :onsite_model
$config = ConfigFile.get_settings_for_environment($settings, $target)
$app_path = File.expand_path(File.dirname(__FILE__))
$server = ($config[:syncserver] || "").sub('/application', '')
$password = ($config[:rhoadmin_password] || "")

namespace :server do
  def rest_rescue
    begin
      yield if block_given?
    rescue RestClient::Exception => e
      puts "Got rest exception:"
      ap e
    end
  end
  
  desc "Sets the current environment target. Must be an existing environment in settings/settings.yml ('development', 'test', etc.)"
  task :set, :env do |t, args|
    raise "No configuration found for '#{args.env}'" unless $settings["#{args.env}".to_sym]
    rake = File.readlines(__FILE__)
    rake.map!{|l| l =~ /^\$target/ ? "$target = :#{args.env}\n"  : l }
    File.open(__FILE__, 'w+') {|f| f.write(rake) }
    Rake::Task['server:clear_token'].invoke
  end
  
  desc 'Shows the current target server and url'
  task :show do 
    puts "Current server is :#{$target}, url is #{$server}"
  end

  login = 'rhoadmin'
  tokenfile = '.rhosync_token'
  
  task :set_token do
    begin
      if File.exists?(tokenfile) 
        puts "reading token file..."
        @token = File.readlines(tokenfile).first.strip
        puts "using persisted token: #{@token}..."
      else
        puts "no persisted token found, authenticating at #{$server}..."
        puts "Posting to: #{$server}login -- #{{ :login => 'rhoadmin', :password => $password }.to_json}"
        res = RestClient.post("#{$server}login", { :login => 'rhoadmin', :password => $password }.to_json, :content_type => :json)
        
        puts "Pre-token cookies #{res.cookies.inspect}"
        
        #The following fix is needed when using rest-client 1.6.1;
        #The make_headers function (lib/restclient/request.rb, line 86) uses CGI::unescape, but we want the cookies
        #submitted to RhoSync to remain escaped. The following code simply replaces all '%' characters with their
        #URL-encoded value of '%25' to prevent escaped characters in the given cookie from being unescaped by
        #rest-client. For example, a given cookie of "1234%3D%0A5" would have been unescaped and sent back to
        #RhoSync as "12345=\n5", but RhoSync expects the cookie to be in its original escaped format.
        preserved_cookies = res.cookies.inject({}){ |h,(key,value)| 
           h[key] = value.gsub('%', '%25')
           h
         }
                
        @token = RestClient.post("#{$server}api/get_api_token",'',{ :cookies => preserved_cookies, })
        
        puts "new token: #{@token}"
        File.open(tokenfile, 'w') {|f| f.write(@token) }
      end
      Rake::Task['server:show'].invoke
    rescue Exception => e
      puts "!!!! Exception thrown: #{e.inspect}"
    end
  end
  
  task :clear_token do
    `rm #{tokenfile}`
  end
  
  task :get_user_token, [:username] => :set_token do |t, args|
    puts "getting user token..."
    res = JSON.parse(RestClient.post(
      "#{$server}api/get_user_token", 
      { 
        :api_token => @token, 
        :username => args[:username]
      }.to_json, 
      :content_type => :json
    ).body)
    ap res
  end
  
  desc "Creates a user with the given password in the system at #{$server}"
  task :create_user, [:login, :password] => :set_token do |t, args|
    RestClient.post("#{$server}api/create_user",
      { 
        :api_token => @token,
        :attributes => { 
          :login => args.login, 
          :password => args.password 
        } 
      }.to_json, 
      :content_type => :json
    )
    puts "Created user #{args.login} with password #{args.password}"
  end
  
  desc "Deletes the user defined by <user_id>"
  task :delete_user, [:user_id] => [:set_token] do |t, args|
    puts "Do you really want to delete #{args.user_id} from #{$server}?? (y/n)"
    if STDIN.gets.chomp == 'y' then
        puts "very well..."
        RestClient.post(
          "#{$server}api/delete_user",
          { :api_token => @token, 
            :user_id => args.user_id }.to_json, 
            :content_type => :json
        )
        puts "User #{args.user_id} deleted"
    end
  end
  
  desc "Lists all users in the system at #{$server}"
  task :list_users => [:set_token] do
    users = RestClient.post(
      "#{$server}api/list_users",
      { :api_token => @token }.to_json, 
      :content_type => :json
    ).body
     puts "\nUSERS:"
    users.gsub(/[\[\]]/, '').split(",").each { |u| puts u }
  end
  
  desc "Reset the user's sync flag to force a full query on the next login"
  task :reset_sync_status, [:user_pattern] => [:set_token] do |t, args|
    abort "User pattern must be specified" unless args[:user_pattern]
    res = JSON.parse(RestClient.post(
      "#{$server}api/reset_sync_status", 
      { 
        :api_token => @token, 
        :user_pattern => args[:user_pattern]
      }.to_json, 
      :content_type => :json
    ).body)
    ap res.sort
  end
  
  desc "Reset the time that the given source for the given user will query the backend to now"
  task :reset_poll_time, [:source_name, :user_name] => [:set_token] do |t,args|
    abort "Source name & user name must be specified" unless args[:source_name] && args[:user_name]
    puts "Resetting poll interval for #{args[:source_name]} for user #{args[:user_name]}"
    begin
      ap RestClient.post(
        "#{$server}api/set_refresh_time",
        { 
          :api_token => @token,
          :source_name => args[:source_name], 
          :user_name => args[:user_name], 
          :refresh_time => 0
        }.to_json, 
        :content_type => :json
      ).body
    rescue RestClient::Exception => e
      puts "Got rest exception:"
      ap e
    end
    
  end
  
  desc "Get the time at which the given source for the given user will query the backend"
  task :get_poll_time, [:source_name, :user_name] => [:set_token] do |t,args|
    abort "Source name & user name must be specified" unless args[:source_name] && args[:user_name]
    begin
      res = RestClient.post(
        "#{$server}api/get_db_doc", 
        { 
          :api_token => @token, 
          :doc => "read_state:application:#{args[:user_name]}:#{args[:source_name]}:refresh_time",
          :data_type => "string"
        }.to_json, 
        :content_type => :json
      ).body
      puts "Got response: #{res}"
      puts "Parsed to #{Time.at(Integer(res))}"
    rescue RestClient::Exception => e
      puts "Got rest exception:"
      ap e
    end
  end
  
  task :quick_performance_check => [:set_token] do |t,args|
    interval = 20 # Number of seconds between checks
    
    loop do
      timer_start = Time.now
      res = JSON.parse(RestClient.post(
        "#{$server}api/get_sync_status", 
        { 
          :api_token => @token, 
          :user_pattern => "*"
        }.to_json, 
        :content_type => :json
      ).body)
      puts "#{Time.now}: Request took #{Time.now-timer_start} seconds"
      sleep(interval)
    end
  end
  
  task :get_sync_status, [:user_pattern] => [:set_token] do |t, args|
    abort "User pattern must be specified" unless args[:user_pattern]
    
    res = JSON.parse(RestClient.post(
      "#{$server}api/get_sync_status", 
      { 
        :api_token => @token, 
        :user_pattern => args[:user_pattern]
      }.to_json, 
      :content_type => :json
    ).body)
    
    ap res.sort
  end
  
  task :get_log => [:set_token] do
    res = RestClient.post(
      "#{$server}api/get_log",
      {
        :api_token => @token
      }.to_json,
      :content_type => :json
    ).body
    
    puts res
  end
  
  desc "pushes objects and invokes the notify method associated with the sources" 
  task :push_objects_notify => [:set_token] do |t, args|
    res = RestClient.post(
      "#{$server}api/push_objects_notify", 
      { 
        :api_token => @token, 
        :user_id => args.user_id || 'dave', 
        :source_id => "Contact", 
        :objects => "objects!!!!"
      }.to_json, 
      :content_type => :json
    )
  end
  
  desc "pushes a delete of object with id object_id of source source_id for user user_id"
  task :push_delete, [:user_id, :source_id, :object_id] => [:set_token] do |t,args|
    abort "user_id, source_id and object_id must be specified" unless args[:user_id] and args[:source_id] and args[:object_id]
    rest_rescue do
      res = RestClient.post(
        "#{$server}api/push_deletes",
        {
          :api_token => @token,
          :user_id => args[:user_id],
          :source_id => args[:source_id],
          :objects => [args[:object_id]]
        }.to_json,
        :content_type => :json
      )
      ap res
    end
  end
  
  desc "manually raise a test exception (should send a notification to ExceptionUtil)" 
  task :test_exception, [:message] => [:set_token] do |t, args|
    puts "posting to #{$server}api/test_exception"
    puts({:api_token => @token, :message => args.message }.to_json)
    
    res = RestClient.post(
      "#{$server}api/test_exception", 
      { 
        :api_token => @token, 
        :message => args.message 
      }.to_json, 
      :content_type => :json
    )
  end

  desc "Sends a push and badge number to a user: rake server:ping[*<user_id>,<message>,<badge>]"
  task :ping, [:user_id, :message, :source, :badge] => [:set_token] do |t, args|
    puts "token is #{@token}"
    ping_params = {
      :api_token => @token,
      :user_id => args.user_id,
      :message => 'thusly have you been pinged',
      :sound => 'hello.mp3',
      :sources => args.source || 'Contact',
      :badge => args.badge || nil
    }

    puts "Pinging #{args.name} at #{$server}api/ping..."
    
    ap ping_params
    begin
      RestClient.post(
        "#{$server}api/ping",
        ping_params.to_json, 
        :content_type => :json
      ) 
      puts "#{args.user_id} has been duly pinged."
    rescue Exception => e
      puts "Unable to ping user #{args.user_id} at #{$server}\n#{e.inspect}"
    end
  end
  
  desc "Sends a badge number to a user: rake server:ping[*<username>,<badge_number>]"
  task :badge, [:user_id, :badge_number] => :set_token do |t, args|
    ping_params = {
      :api_token => @token,
      :user_id => args.user_id,
      :sound => 'hello.mp3',
      :badge => args.badge_number
    }
    ap ping_params
    puts "Badging #{args.user_id}..."
    RestClient.post(
      "#{$server}api/ping",ping_params.to_json, 
      :content_type => :json
    ) 
    puts "#{args.name} has been duly badged."
  end

  desc "Resets the database in the server environment at #{$server}"
  task :reset_db => [:set_token] do
    puts "do you really want to reset the db?? (y/n)"
    if STDIN.gets.chomp == 'y' then
      puts "very well..."
      RestClient.post("#{$server}api/reset",
       { :api_token => @token }.to_json, 
         :content_type => :json
      )
      puts "db has been reset"
    end
  end
  
  desc "Gets the db_doc for the given user and model"
  task :get_db_doc, [:user_id, :model] => [:set_token] do |t, args|
    res = RestClient.post(
      "#{$server}api/get_db_doc", 
      { 
        :api_token => @token, 
        :doc => "source:application:#{args.user_id}:#{args.model}:md"
      }.to_json, 
      :content_type => :json
    ).body
    ap JSON.parse(res)
  end
  
  
  
  def get_md(username, model)
    res = RestClient.post(
      "#{$server}api/get_db_doc", 
      { 
        :api_token => @token, 
        :doc => "source:application:#{username}:#{model}:md"
      }.to_json, 
      :content_type => :json
    ).body
    JSON.parse(res)
  end
  
  def get_users
    res = RestClient.post(
      "#{$server}api/list_users", 
      { 
        :api_token => @token
      }.to_json, 
      :content_type => :json
    ).body
    JSON.parse(res)
  end
  
  def get_clients(user_id)
    res = RestClient.post("#{$server}api/list_clients", 
      { 
        :api_token => @token, 
        :user_id => user_id 
      }.to_json, 
     :content_type => :json
    ).body
    JSON.parse(res)
  end
  
  def get_client_params(client_id)
    res = RestClient.post(
      "#{$server}api/get_client_params", 
      { 
        :api_token => @token, 
        :client_id => client_id 
      }.to_json, 
      :content_type => :json
    ).body
    JSON.parse(res)
  end
  
  desc "check data integrity for all users matching regex pattern <user_pattern> (i.e. use 'check_integrity[.]' to check all users)"
  task :check_integrity, [:user_pattern] => [:set_token] do |t, args|
    abort "!!! User regex pattern must be specified (i.e. 'rake server:check_integrity[\"a[0-9]\"]' to check integrity for all users that match the agent code pattern)" unless args[:user_pattern]
    #get all users from RhoSync, filter based on pattern given
    filtered_users = get_users.reject{|user| user[Regexp.new(args.user_pattern)].nil?}
    
    integrity_check_results = filtered_users.reduce([]){|sum,user|
      opps = get_md(user, 'Opportunity')
      contacts = get_md(user, 'Contact')
      
      opp_contact_relational_check_failed = false
      contact_field_check_failed = false
    
      opps.each{|k,v|
        contact_id = v['contact_id']
        opp_contact_relational_check_failed = true unless contact_id
        parent_contact = contacts[contact_id]
        opp_contact_relational_check_failed = true unless parent_contact
        break if opp_contact_relational_check_failed
      }
    
      contact_required_fields = ['firstname','lastname']
      opp_required_fields = ['contact_id']
    
      contacts.each{|k,v|    
        missing_required_fields = contact_required_fields.reject{|crf| v.include?(crf)}
        contact_field_check_failed = true unless missing_required_fields.count == 0
        break if contact_field_check_failed
      }
      
      failures = []
      failures << "Opportunity->contact relational check" if opp_contact_relational_check_failed
      failures << "Contact required field check" if contact_field_check_failed
      
      sum << {:user => user, :failures => failures, :opp_count => opps.count, :contact_count => contacts.count }
    }
    
    integrity_check_results.sort!{|x,y|
      failure_count_comp = y[:failures].count <=> x[:failures].count
      user_comp = x[:user] <=> y[:user]
      
      failure_count_comp == 0 ? user_comp : failure_count_comp
    }
    
    integrity_check_results.each{|result|
      has_failures = result[:failures].count > 0
      prepend = has_failures ? ' !!!  ' : '      '
      print "#{prepend}Integrity check #{has_failures ? 'failed' : 'passed'} for user #{result[:user]}; "
      puts " checked #{result[:opp_count]} opportunities and #{result[:contact_count]} contacts."
      puts "\tFailed checks: #{result[:failures].awesome_inspect(:multiline => false)}" if has_failures
    }
    
  end
  
	
	desc "Compares all the data in Rhosync with all the in-scope data in CRM"
	task :validate_user_data_against_crm, [:user_pattern] do |t,args|
	  puts "\n*************Start validating Redis data against CRM:"

    DataValidation.validate($config[:crm_path],$config[:redis_url],$config[:redis_port],args[:user_pattern])

    puts "Done!!!!!!!!!!!!!\n\n"
  end
  
  def get_client_param_value(client_params_hash, param_name)
    client_params_hash.each{|value|
      return value['value'] if value['name'] == param_name
    } if client_params_hash
    
    nil
  end
  
  def client_has_pin?(client_params_hash)
    client_params_hash.each{|value|
      return true if (value['name'] == 'device_pin') && value['value'] && (value['value'].length > 0)
    }
    
    false
  end
  
  desc "shows all users matching regex pattern <user_pattern> that do not have a push pin for at least one of their devices"
  task :check_push_pins, [:user_pattern] => [:set_token] do |t, args|
    abort "!!! User regex pattern must be specified (i.e. 'server:check_push_pins[\"a[0-9]\"]' to check the push pins for all users that match the agent code pattern)" unless args[:user_pattern]
    #get all users from RhoSync, filter based on pattern given
    filtered_users = get_users.reject{|user| user[Regexp.new(args.user_pattern)].nil?}
    
    # get clients & params for users
    user_client_params = filtered_users.reduce({}){|sum,user_id|
      user_clients = get_clients(user_id)
      sum[user_id] = user_clients.reduce({}){|sum2,client_id| 
        sum2[client_id] = get_client_params(client_id)
        sum2
      }
      sum
    }
    
    user_pin_params = user_client_params.reduce([]){|sum,(user,clients)| 
      pinless_clients = clients.reject{|client_id,client_params| client_has_pin?(client_params)}
      sum << {:user_id => user, :clients => clients, :pinless_clients => pinless_clients}
      sum
    }
    
    user_pin_params.sort!{|x,y|
      count_comp = y[:pinless_clients].count <=> x[:pinless_clients].count
      user_id_comp = x[:user_id] <=> y[:user_id]
      
      count_comp == 0 ? user_id_comp : count_comp
    }
    
    user_pin_params.each{|val| 
      prepend = val[:pinless_clients].count > 0 ? ' !!!  ' : '      '
      puts "#{prepend}#{val[:pinless_clients].count} of #{val[:clients].count} clients for user #{val[:user_id]} have no push pins: #{val[:pinless_clients].keys.awesome_inspect(:multiline => false)}"
    }
  end
  
  desc "shows platform breakdowns for devices associated with users matching the given pattern <user_pattern> (i.e. 'rake server:gather_device_stats[\"a[0-9]\"]' to show device stats for agents only)"
  task :gather_device_stats, [:user_pattern] => [:set_token] do |t, args|
    abort "!!! User regex pattern must be specified (i.e. 'server:check_device_pins[\"a[0-9]\"]' to gather device stats for all users that match the agent code pattern)" unless args[:user_pattern]
    #get all users from RhoSync, filter based on pattern given
    filtered_users = get_users.reject{|user| user[Regexp.new(args.user_pattern)].nil?}
    
    # get clients & params for users
    user_client_params = filtered_users.reduce({}){|sum,user_id|
      user_clients = get_clients(user_id)
      sum[user_id] = user_clients.reduce({}){|sum2,client_id| 
        sum2[client_id] = get_client_params(client_id)
        sum2
      }
      sum
    }
    
    platform_counts = {}
    
    user_client_params.values.each{|clients|
      clients.values.each{|client_params|        
        device_type = get_client_param_value(client_params, 'device_type')
        platform_counts[device_type] ||= 0
        platform_counts[device_type] += 1
      }
    }
    
    puts "\nTotal device count: #{platform_counts.values.reduce(0){|sum,value| sum += value}}"
    puts "Platform breakdown:"
    ap(platform_counts,:plain => true)
  end
  
  namespace :opportunity do
    desc "Creates <num_contacts> opportunities for <user_id> with generated attributes in the current target server."
    task :create, [:user_id, :first_name, :last_name]  => :set_token do |t, args|

    contact = [{"firstname" => args.first_name || Faker::Name.first_name,
                "lastname" => args.last_name || Faker::Name.last_name,
                 "emailaddress1" => "6rco@create.com",
                 "contactid" => "fd47db4d-0ccb-df11-9bfd-0050568d0f01"}]
                 
      20.times { break if fork.nil? }
    
      25.times do
       res = RestClient.post(
         "#{$server}api/push_objects_notify", 
         { 
           :api_token => @token, 
           :user_id => args.user_id || 'dave', 
           :source_id => "Opportunity", 
           :objects => contact
         }.to_json, 
         :content_type => :json
       )
        puts "Created new Contact:"
        ap contact
        puts "Response:"
        ap res
      end
    end
  end
  
  task :test_threads, [:user_id, :first_name, :last_name]  => :set_token do |t, args|
    contact = [{"firstname" => args.first_name || Faker::Name.first_name,
                "lastname" => args.last_name || Faker::Name.last_name,
                 "emailaddress1" => "6rco@create.com",
                 "contactid" => "fd47db4d-0ccb-df11-9bfd-0050568d0f01"}]
                 
    threads = []
         count = 5
         ittr = 5
         1.upto(count) do |i|
           threads << Thread.new do |j|
             1.upto(ittr) do
               begin
                res = RestClient.post(
                  "#{$server}api/push_objects_notify", 
                  { 
                    :api_token => @token, 
                    :user_id => args.user_id || 'dave', 
                    :source_id => "Opportunity", 
                    :objects => contact
                  }.to_json, 
                  :content_type => :json
                )
                 puts "Created new Contact #{i} - #{j}:"
                 ap contact
                 puts "Response:"
                 ap res
               rescue Exception => e
                 puts "EXCEPTION: #{e} #{i} - #{j}, res: #{res.inspect}"
               end
             end
           end
         end
         threads.each {|thread| thread.join }
  end

  namespace :contact do 
    desc "Gives the number of contacts for the given user"
    task :count, [:user_id] => [:set_token] do |t,args|
      res = RestClient.post(
        "#{$server}api/get_db_doc", 
        { 
          :api_token => @token, 
          :doc => "source:application:#{args.user_id}:Contact:md"
        }.to_json, 
        :content_type => :json
      ).body
      puts "Contact count for #{args.user_id}: #{JSON.parse(res).count}"
    end
    
    desc "Creates <num_contacts> contacts for <user_id> with generated attributes in the current target server."
    task :create, [:user_id, :num_contacts, :first_name, :last_name]  => :set_token do |t, args|
      contacts = (args.num_contacts || 1).to_i.times.reduce({}) do |sum, i|  
        sum[rand(10**20)] = {
          "firstname" => args.first_name || Faker::Name.first_name,
          "lastname" => args.last_name || Faker::Name.last_name,
          "cssi_preferredphone" => 'mobile',
          "mobilephone" =>  Faker::PhoneNumber.phone_number,
          };
          sum
      end
      
      5.times do
        res = RestClient.post(
          "#{$server}api/push_mapped_objects", 
          { 
            :api_token => @token, 
            :user_id => args.user_id || 'dave', 
            :source_id => "Contact", 
            :objects => contacts
          }.to_json, 
          :content_type => :json
        )
        puts "Created #{(args.num_contacts || 1)} new Contact(s):"
        ap contacts
        puts "Response:"
        ap res
      end
    end
  end
  
  desc "temp task for Passenger bug fix"
  task :fix_bootstrap do
    ENV['REDIS'] = "redis://nrhrho103:6379"
    ROOT_PATH = '.'
    require 'rhosync/server'
    require 'application'
  end
end