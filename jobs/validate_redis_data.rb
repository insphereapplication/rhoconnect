app_path = File.expand_path(File.join(File.dirname(__FILE__))) 
require "#{app_path}/../util/config_file"
require "#{app_path}/../helpers/crypto"
require "#{app_path}/../jobs/rhosync_resque_job"
require "#{app_path}/../util/email_util"

class ValidationHelpers
  class << self
    include RhosyncResqueJob
    
    def sync_status
      @sync_status ||= rhosync_api.get_sync_status("*")
    end
    
    def users
      @users ||= rhosync_api.get_all_users
    end
    
    def credentials
      @credentials ||= users.reduce({}){ |sum,user| sum[user] = rhosync_api.get_user_password(user); sum }
    end
      
    def get_rhosync_source_data(user, docname)
      docs = rhosync_api.list_source_docs(docname, user)      
      data = rhosync_api.get_db_doc( docs['md'] )
    end
    
    def source_initialized?(user, source)
      user_initialized_sources = sync_status[:initialized_sources][user]
      user_initialized_sources && user_initialized_sources.include?(source.downcase)
    end
    
    def get_crm_data(source, user, pw)
      res = RestClient.post("#{CONFIG[:crm_path]}/#{source}",
        { :username => user, 
          :password => pw },
          :content_type => :json
      ).body        
      JSON.parse(res)
    end
  end
end

class ValidationCheck  
  def initialize(friendly_name)
    @passed = true
    @friendly_name = friendly_name
  end
  
  def passed
    @passed
  end
  
  def failed
    !passed
  end
  
  def result_summary
    "#{@friendly_name} check: #{passed ? 'PASS' : 'FAIL'}."
  end
  
  def result_details
    "Detailed results for #{@friendly_name} check: "
  end
  
  def log(message)
    puts message
  end
end

class OpportunityCheck < ValidationCheck
  def initialize
    super("Opportunity true-up")
    @results = {}
    run
  end
  
  def run
    ValidationHelpers.users.each do |user|
      begin
        log "*"*10 + "Checking user #{user}"
        opp_data = ValidationHelpers.get_rhosync_source_data(user, 'Opportunity')
        opp_ids_rhosync = opp_data.keys
    
        expiring_opp_ids = CleanOldOpportunityData.get_expired_opportunities(opp_data, -1).map{|key,value| key} # gather list of opps that have already expired or will expire within 24 hours
    
        opp_ids_crm = ValidationHelpers.get_crm_data('opportunity', user, ValidationHelpers.credentials[user]).map { |i| i['opportunityid'] }  

        opp_ids_in_rhosync_not_crm = opp_ids_rhosync.reject { |id| opp_ids_crm.include?(id) or expiring_opp_ids.include?(id) }
        log "Opportunities in Rhosync not in CRM: #{opp_ids_in_rhosync_not_crm.count}"
        
        opp_ids_in_crm_not_rhosync = opp_ids_crm.reject { |id| opp_ids_rhosync.include?(id) }
        log "Opportunities in CRM not in Rhosync: #{opp_ids_in_crm_not_rhosync.count}"
    
        user_passed = !ValidationHelpers.source_initialized?(user, 'opportunity') || (opp_ids_in_rhosync_not_crm.count == 0 && opp_ids_in_crm_not_rhosync.count == 0)
        
        @results[user] = {:passed => user_passed, :extra_rhosync_opps => opp_ids_in_rhosync_not_crm, :extra_crm_opps => opp_ids_in_crm_not_rhosync}
      rescue Exception => ex
        log "#"*80
        log "Exception encountered: #{ex.awesome_inspect}"
        log "#"*80
      end
    end
  end
  
  def failures
    @failures ||= @results.select{|key,value| !value[:passed] }
  end
  
  def agent_failures
    @agent_failures ||= failures.select{|key,value| key =~ /^[aA][0-9]{5}$/}
  end
  
  def other_failures
    @other_failures ||= failures.reject{|key,value| agent_failures.include?(key)}
  end
  
  def passed
    @passed ||= (agent_failures.count > 0)
  end
  
  def result_summary
    total_user_count = ValidationHelpers.users.count
    super + " #{agent_failures.count} agents and #{other_failures.count} other users failed the opportunity check out of #{total_user_count} total users."
  end
  
  def result_details
    details = failures.reduce([]){|sum,(user,result)|
      sum << "#{user} had #{result[:extra_rhosync_opps].count} extra opps in RhoSync and #{result[:extra_crm_opps].count} extra opps in CRM."
      sum
    }.join("\n")
    super + "\n#{details}"
  end
end


class ValidateRedisData
  @queue = :validate_redis_data

  class << self
    def send_email(email_body)
      ExceptionUtil.rescue_and_reraise do
        to = CONFIG[:resque_data_validation_email_group]
        subject = "RhoSync Data Validation Results - " + Time.now.strftime("%m%d%Y")
        EmailUtil.send_mail(to, subject, email_body)
      end
    end

    def perform
      puts "*"*20 + "Starting Validate_Redis_Data job"
      puts "Target rhosync host: #{CONFIG[:resque_worker_rhosync_api_host]}"
      
      checks = [OpportunityCheck.new]
      
      environment = CONFIG[:env]
      start_time = Time.now
      # user_count = users.count
      # device_count = 0
      # test_results = {
      #   :mismatched_opps => {},
      #   :integrity_check => {},
      #   :push_pin_check => {},
      #   :unhandled_client_exceptions => {},
      #   :dead_redis_locks => {}
      # }
      #     
      # summary_results = {
      #   'environment' => CONFIG[:env],
      #   'run_start' => Time.now,
      #   'users' => {
      #     'total' => users.count,
      #     'mismatched' => {
      #       'contacts_userlist' => [],
      #       'opportunities_userlist' => [],
      #       'integrity_check_userlist' => [],
      #       'unhandled_client_exception_userlist' => []
      #     }
      #   },
      #   'devices' => {
      #     'total' => 0, 
      #     'mismatched_pins_userlist' => []
      #   }
      # }
      
      #get user passwords to use during REST calls to the Proxy
      # passwords = Hash.new
      # users.each { |user| passwords[user] = rhosync_api.get_user_password(user) }
      
      
  
      # users.each do |user|
      #         begin
      #           puts "*"*10 + "Checking user #{user}"
      #           user_initialized_sources = sync_status[:initialized_sources][user]
      #           user_refresh_times = sync_status[:refresh_times][user]
      #           puts "Initialized sources: #{InsiteLogger.format_for_logging(user_init_flags)}"
      #           puts "Refresh times: #{InsiteLogger.format_for_logging(user_refresh_times)}"
      #       
      #           #Compare opportunity data
      #           opp_data = get_rhosync_source_data(rhosync_api, user, 'Opportunity')
      #           opp_ids_rhosync = opp_data.keys
      #           
      #           expiring_opp_ids = CleanOldOpportunityData.get_expired_opportunities(opp_data, -1).keys # gather list of opps that have already expired or will expire within 24 hours
      #           
      #           opp_ids_crm = get_crm_data('opportunity', user, passwords[user]).map { |i| i['opportunityid'] }  
      #     
      #           opp_ids_in_rhosync_not_crm = opp_ids_rhosync.reject { |id| opp_ids_crm.include?(id) or expiring_opp_ids.include?(id) }
      #           puts "Opportunities in Rhosync not in CRM: #{opp_ids_in_rhosync_not_crm.count}"
      #           puts opp_ids_in_rhosync_not_crm.inspect unless opp_ids_in_rhosync_not_crm.count == 0
      # 
      #           opp_ids_in_crm_not_rhosync = opp_ids_crm.reject { |id| opp_ids_rhosync.include?(id) }
      #           puts "Opportunities in CRM not in Rhosync: #{opp_ids_in_crm_not_rhosync.count}"
      #           puts opp_ids_in_crm_not_rhosync.inspect unless opp_ids_in_crm_not_rhosync.count == 0
      # 
      #           opp_sync_status = user_initialized_sources && user_initialized_sources.include?('opportunity')
      #           
      #           opp_test_passed = 
      #           
      #           test_results[:mismatched_opps][user] = {:extra_rhosync_opps => opp_ids_in_rhosync_not_crm, :extra_crm_opps => opp_ids_in_crm_not_rhosync}
      #           
      #           summary_results['users']['mismatched']['opportunities_userlist'] << user if opp_ids_in_crm_not_rhosync.count > 0
      # 
      #           #3.Integrity check for Rhosync data
      #           opps_without_contacts = opp_ids_rhosync.reject { |id| contact_ids_rhosync.include?( opp_data[id]['contact_id'] ) }
      #           puts "Opportunities in Rhosync with no attached contacts: #{opps_without_contacts.count}"
      #           puts opps_without_contacts.inspect unless opps_without_contacts.count == 0
      # 
      #           summary_results['users']['mismatched']['integrity_check_userlist'] << user if opps_without_contacts.count > 0
      #     
      #           #4.Device key check
      #           #Only check if the user pattern is a12345
      #           if user =~/(a|A)\d{5}/      
      #             user_devices = rhosync_api.get_user_devices(user)
      #             next if user_devices.empty?
      #     
      #             summary_results['devices']['total'] += user_devices.count      
      #     
      #             puts "Devices in Rhosync: #{user_devices.count}"
      #     
      #             devices_missing_pin = []
      #             user_devices.each do |device_id|
      #               device_pin = rhosync_api.get_device_params(device_id).select{ |k| k['name'] == 'device_pin' }.first        
      #               devices_missing_pin << device_id if device_pin.nil? || (!device_pin.nil? && device_pin['value'].nil?)      
      #             end
      #   
      #             if devices_missing_pin.count > 0
      #               summary_results['devices']['mismatched_pins'] += devices_missing_pin.count    
      #               summary_results['devices']['mismatched_pins_userlist']  << '#{user}:#{devices_missing_pin.count} of #{user_devices.count},')      
      #               puts "#{devices_missing_pin.count} of #{user_devices.count} devices have no PIN"
      #               devices_missing_pin.each{ |id| puts id }
      #             else
      #               puts "All #{user_devices.count} devices have a PIN"  
      #             end
      #           end    
      #           
      #         #5. Check for unhandled client exceptions
      #         client_exception_data = get_rhosync_source_data(rhosync_api, user, 'ClientException')
      #         client_exception_counter = 0
      #         client_exception_data.each do |client_exception|
      #         if (client_exception.exception_type = 'E400' || client_exception.exception_type = 'E500') && (client_exception.server_created_on + (60 * 60 * 24) > Time.now)
      #           client_exception_counter += 1
      #         end
      #         
      #         summary_results['users']['unhandled_client_exception_userlist'] << ('#{user}:#{client_exception_counter}') if client_exception_counter > 0
      # 
      #         end        
      #         rescue Exception => ex
      #           puts "#"*80
      #           puts "Exception encountered: #{ex.awesome_inspect}"
      #           puts "#"*80
      #         end
      #       end    
    
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
