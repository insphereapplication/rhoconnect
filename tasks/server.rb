require 'yaml'
require 'ap'
require 'faker'
gem 'rest-client', '=1.4.2'

$settings_file = 'settings/settings.yml'
$config = YAML::load_file($settings_file)
$app_path = File.expand_path(File.dirname(__FILE__))
$target = :production
$server = ($config[$target] ? $config[$target][:syncserver] : "").sub('/application', '')

namespace :server do
  desc "Sets the current environment target. Must be an existing environment in settings/settings.yml ('development', 'test', etc.)"
  task :set, :env do |t, args|
    raise "No configuration found for '#{args.env}'" unless $config["#{args.env}".to_sym]
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
  password = ''
  tokenfile = '.rhosync_token'
  
  task :set_token do
    begin
      if File.exists?(tokenfile) 
        puts "reading token file..."
        @token = File.readlines(tokenfile).first.strip
        puts "using persisted token..."
      else
        puts "no persisted token found, authenticating at #{$server}..."
        res = RestClient.post("#{$server}login", { :login => 'rhoadmin', :password => "" }.to_json, :content_type => :json)
        @token = RestClient.post("#{$server}api/get_api_token",'',{ :cookies => res.cookies })
        File.open(tokenfile, 'w') {|f| f.write(@token) }
        puts "new token: #{@token}"
      end
      Rake::Task['server:show'].invoke
    rescue Exception => e
      puts "!!!! Exception thrown: #{e.inspect}"
    end
  end
  
  task :clear_token do
    `rm #{tokenfile}`
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

  desc "Sends a push and badge number to a user: rake server:ping[*<user_id>,<message>,<badge>]"
  task :ping, [:user_id, :message, :source, :badge] => [:set_token] do |t, args|
    puts "token is #{@token}"
    ping_params = {
      :api_token => @token,
      :user_id => args.user_id,
      :message => 'thusly have you been pinged',
      :vibrate =>  "2000",
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
      :vibrate =>  "2000",
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
  task :get_db_doc, :user_id, :model, :needs => [:set_token] do |t, args|
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
  
  # namespace :opportunity do
  #   desc "Creates <num_contacts> contacts for <user_id> with generated attributes in the current target server."
  #   task :create, [:user_id, :num_opportunities, :first_name, :last_name, :sort_ordinal]  => :set_token do |t, args|
  #     contacts = (args.num_contacts || 1).to_i.times.reduce({}) do |sum, i|  
  #       sum[rand(10**20)] = {
  #         "city" => Faker::Address.city,
  #         "created_on" => Time.now.to_s,
  #         "updated_on" => Time.now.to_s,
  #         "first_name" => args.first_name || Faker::Name.first_name,
  #         "last_name" => args.last_name || Faker::Name.last_name,
  #         "date_of_birth" => "#{rand(12)}/#{rand(28)}/#{rand(99)}",
  #         "state" => Faker::Address.us_state
  #         };
  #         sum
  #     end
  #     
  #     res = RestClient.post(
  #       "#{$server}api/push_objects_notify", 
  #       { 
  #         :api_token => @token, 
  #         :user_id => args.user_id || 'dave', 
  #         :source_id => "Contact", 
  #         :objects => contacts
  #       }.to_json, 
  #       :content_type => :json
  #     )
  #     puts "Created #{(args.num_contacts || 1)} new Contact(s):"
  #     ap contacts
  #     puts "Response:"
  #     ap res
  #   end
  #   
  # end

  namespace :contact do 
    desc "Gives the number of contacts for the given user"
    task :count, :user_id, :needs => [:set_token] do |t,args|
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
    task :create, [:user_id, :num_contacts, :first_name, :last_name, :sort_ordinal]  => :set_token do |t, args|
      contacts = (args.num_contacts || 1).to_i.times.reduce({}) do |sum, i|  
        sum[rand(10**20)] = {
          "sort_ordinal" => args.sort_ordinal || -(Time.now.to_i),
          "city" => Faker::Address.city,
          "created_on" => Time.now.to_s,
          "updated_on" => Time.now.to_s,
          "first_name" => args.first_name || Faker::Name.first_name,
          "last_name" => args.last_name || Faker::Name.last_name,
          "date_of_birth" => "#{rand(12)}/#{rand(28)}/#{rand(99)}",
          "state" => Faker::Address.us_state
          };
          sum
      end
      
      res = RestClient.post(
        "#{$server}api/push_objects_notify", 
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