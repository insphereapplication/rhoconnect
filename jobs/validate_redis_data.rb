app_path = File.expand_path(File.join(File.dirname(__FILE__))) 
require "#{app_path}/../util/config_file"
require "#{app_path}/../helpers/crypto"
require "#{app_path}/../jobs/rhosync_resque_job"
require "#{app_path}/../util/email_util"

class ValidateRedisData
  @queue = :validate_redis_data

  class << self
    include RhosyncResqueJob

    def send_email(email_body)
      ExceptionUtil.rescue_and_reraise do
        to = CONFIG[:resque_data_validation_email_group]
        subject = "RhoSync Data Validation Results - " + Time.now.strftime("%m%d%Y")
        EmailUtil.send_mail(to, subject, email_body)
      end
    end
      
    def get_rhosync_source_data(rhosync_api, user, docname)
      docs = rhosync_api.list_source_docs(docname, user)      
      data = rhosync_api.get_db_doc( docs['md'] )
    end  

    def get_crm_data(source, user, pw)
      res = RestClient.post("#{CONFIG[:crm_path]}/#{source}",
        { :username => user, 
          :password => pw },
          :content_type => :json
      ).body        
      JSON.parse(res)
    end

    def perform
      puts "*"*20 + "Starting Validate_Redis_Data job"
      puts "Target rhosync host: #{CONFIG[:resque_worker_rhosync_api_host]}"  

      users = rhosync_api.get_all_users
    
      summary_results = {
        'environment' => CONFIG[:env],
        'run_start' => Time.now,
        'users' => {
          'total' => users.count,
          'mismatched' => {
            'contacts_userlist' => [],
            'opportunities_userlist' => [],
            'integrity_check_userlist' => [],
            'unhandled_client_exception_userlist' => []
          }
        },
        'devices' => {
          'total' => 0, 
          'mismatched_pins_userlist' => []
        }
      }
      
      #get user passwords to use during REST calls to the Proxy
      passwords = Hash.new
      users.each { |user| passwords[user] = rhosync_api.get_user_password(user) }
  
      users.each do |user|
        begin
          puts "*"*10 + "Checking user #{user}"
  
          #1.compare Contact data
          contact_ids_rhosync = get_rhosync_source_data(rhosync_api, user, 'Contact').keys
          
          contact_ids_crm = get_crm_data('contact', user, passwords[user]).map { |i| i['contactid'] }            
    
          contact_ids_in_rhosync_not_crm = contact_ids_rhosync.reject { |id| contact_ids_crm.include?(id) }
          puts "Contacts in Rhosync not in CRM: #{contact_ids_in_rhosync_not_crm.count}"
          puts contact_ids_in_rhosync_not_crm.inspect unless contact_ids_in_rhosync_not_crm.count == 0

          contact_ids_in_crm_not_rhosync = contact_ids_crm.reject { |id| contact_ids_rhosync.include?(id) }
          puts"Contacts in CRM not in Rhosync: #{contact_ids_in_crm_not_rhosync.count}"
          puts contact_ids_in_crm_not_rhosync.inspect unless contact_ids_in_crm_not_rhosync.count == 0
    
          summary_results['users']['mismatched']['contacts_userlist'] << user unless contact_ids_in_crm_not_rhosync.count == 0
             
      
          #2.compare Opportunity data
          opp_data = get_rhosync_source_data(rhosync_api, user, 'Opportunity')
          opp_ids_rhosync = opp_data.keys
          
          opp_ids_crm = get_crm_data('opportunity', user, passwords[user]).map { |i| i['opportunityid'] }  
    
          opp_ids_in_rhosync_not_crm = opp_ids_rhosync.reject { |id| opp_ids_crm.include?(id) }
          puts "Opportunities in Rhosync not in CRM: #{opp_ids_in_rhosync_not_crm.count}"
          puts opp_ids_in_rhosync_not_crm.inspect unless opp_ids_in_rhosync_not_crm.count == 0

          opp_ids_in_crm_not_rhosync = opp_ids_crm.reject { |id| opp_ids_rhosync.include?(id) }
          puts "Opportunities in CRM not in Rhosync: #{opp_ids_in_crm_not_rhosync.count}"
          puts opp_ids_in_crm_not_rhosync.inspect unless opp_ids_in_crm_not_rhosync.count == 0
          
          summary_results['users']['mismatched']['opportunities_userlist'] << user if opp_ids_in_crm_not_rhosync.count > 0

          #3.Integrity check for Rhosync data
          opps_without_contacts = opp_ids_rhosync.reject { |id| contact_ids_rhosync.include?( opp_data[id]['contact_id'] ) }
          puts "Opportunities in Rhosync with no attached contacts: #{opps_without_contacts.count}"
          puts opps_without_contacts.inspect unless opps_without_contacts.count == 0

          summary_results['users']['mismatched']['integrity_check_userlist'] << user if opps_without_contacts.count > 0
    
          #4.Device key check
          #Only check if the user pattern is a12345
          if user =~/(a|A)\d{5}/      
            user_devices = rhosync_api.get_user_devices(user)
            next if user_devices.empty?
    
            summary_results['devices']['total'] += user_devices.count      
    
            puts "Devices in Rhosync: #{user_devices.count}"
    
            devices_missing_pin = []
            user_devices.each do |device_id|
              device_pin = rhosync_api.get_device_params(device_id).select{ |k| k['name'] == 'device_pin' }.first        
              devices_missing_pin << device_id if device_pin.nil? || (!device_pin.nil? && device_pin['value'].nil?)      
            end
  
            if devices_missing_pin.count > 0
              summary_results['devices']['mismatched_pins'] += devices_missing_pin.count    
              summary_results['devices']['mismatched_pins_userlist']  << '#{user}:#{devices_missing_pin.count} of #{user_devices.count},')      
              puts "#{devices_missing_pin.count} of #{user_devices.count} devices have no PIN"
              devices_missing_pin.each{ |id| puts id }
            else
              puts "All #{user_devices.count} devices have a PIN"  
            end
          end    
          
        #5. Check for unhandled client exceptions
        client_exception_data = get_rhosync_source_data(rhosync_api, user, 'ClientException')
        client_exception_counter = 0
        client_exception_data.each do |client_exception|
        if (client_exception.exception_type = 'E400' || client_exception.exception_type = 'E500') && (client_exception.server_created_on + (60 * 60 * 24) > Time.now)
          client_exception_counter += 1
        end
        
        summary_results['users']['unhandled_client_exception_userlist'] << ('#{user}:#{client_exception_counter}') if client_exception_counter > 0

        end        
        rescue Exception => ex
          puts "#"*80
          puts "Exception encountered: #{ex.awesome_inspect}"
          puts "#"*80
        end
      end    
    
      puts "*"*15 + "Sending email with summary data"
    
      # send an email with the results
      file_path = File.expand_path(File.join(File.dirname(__FILE__))) + '/templates/validation_email.erb'
      email_template = ERB.new( File.read(file_path), nil, '<>')
      result = email_template.result(binding)
      send_email(result)

      puts "*"*20 + "Done with Validate_Redis_Data!"
    end
  end
end
