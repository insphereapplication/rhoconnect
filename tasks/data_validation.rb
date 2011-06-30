app_path = File.expand_path(File.join(File.dirname(__FILE__))) 
require "#{app_path}/../util/config_file"
require "#{app_path}/../util/redis_util"
require "#{app_path}/../helpers/crypto"

class DataValidation
  class << self
    def get_user_password(username)    
      encryptedPassword = Store.get_value("username:#{username.downcase}:password")
      Crypto.decrypt( encryptedPassword )
    end

    def validate(proxy_url, redis_host, redis_port, user_pattern)
      RedisUtil.connect(redis_host, redis_port)      
      usernames = []
      RedisUtil.get_keys("user:#{user_pattern}:rho__id").each do |key|
        usernames << RedisUtil.get_value(key)
      end
      usernames.sort!
      puts "Validating users #{usernames.join(", ")}"
      usernames.each do |username|
        puts "\n\n" + "*"*10 + "User #{username}:"
        validate_user_data_against_crm(proxy_url,username)
      end
    end
    
    private 
    
    def validate_user_data_against_crm(proxy_url,username)      
  
      #prestep 1: check if the user is in Redis at all
      user_keys = RedisUtil.get_keys("client:application:#{username}")
  
      if user_keys.count == 0
        puts "User #{username} has no client:application keys in the Redis database"
      else
        #prestep 2: get the contact's password
        password = get_user_password(username)
    
        #1.Contacts validation  
        puts ""
        res = RestClient.post("#{proxy_url}/contact",
          { :username => username, 
            :password => password },
            :content_type => :json
        ).body
        contact_ids_from_crm = JSON.parse(res).map { |i| i['contactid'] }  
        puts "Contacts in CRM: #{contact_ids_from_crm.count}"  
  
        contacts_on_device = RedisUtil.get_md('Contact', username)
        puts "Contacts on device: #{contacts_on_device.count}"
  
        contact_ids_on_device_not_in_crm = contacts_on_device.keys.reject do |id|
          contact_ids_from_crm.include?(id)
        end
        puts "Contacts on device not in CRM: #{contact_ids_on_device_not_in_crm.count}"
        puts contact_ids_on_device_not_in_crm.inspect unless contact_ids_on_device_not_in_crm.count == 0
  
        contact_ids_in_crm_not_on_device = contact_ids_from_crm.reject do |id|
          contacts_on_device.keys.include?(id)
        end
        puts "Contacts in CRM not on device: #{contact_ids_in_crm_not_on_device.count}"
        puts contact_ids_in_crm_not_on_device.inspect unless contact_ids_in_crm_not_on_device.count == 0
  
        #2.Opportunities validation  
        puts ""
        res = RestClient.post("#{proxy_url}/opportunity",
          { :username => username, 
            :password => password },
            :content_type => :json
        ).body
        opp_ids_from_crm = JSON.parse(res).map { |i| i['opportunityid'] }  
        puts "Opps in CRM: #{opp_ids_from_crm.count}"  
  
        opps_on_device = RedisUtil.get_md('Opportunity', username)
        puts "Opps on device: #{opps_on_device.keys.count}"
    
        opp_ids_on_device_not_in_crm = opps_on_device.keys.reject do |id|
          opp_ids_from_crm.include?(id)
        end
        puts "Opps on device not in CRM: #{opp_ids_on_device_not_in_crm.count}"
        puts opp_ids_on_device_not_in_crm.inspect unless opp_ids_on_device_not_in_crm.count == 0
  
        opp_ids_in_crm_not_on_device = opp_ids_from_crm.reject do |id|
          opps_on_device.keys.include?(id)
        end
        puts "Opps in CRM not on device: #{opp_ids_in_crm_not_on_device.count}"
        puts opp_ids_in_crm_not_on_device.inspect unless opp_ids_in_crm_not_on_device.count == 0
  
        #3.Integrity check for on-device data
        puts ""
        opps_without_contacts = opps_on_device.keys.reject do |id|
          contacts_on_device.keys.include?( opps_on_device[id]['contact_id'] )
        end
        puts "Opps on device with no attached contacts: #{opps_without_contacts.count}"
        puts opps_without_contacts.inspect unless opps_without_contacts.count == 0
  
        #4.Device push PIN check
        # puts ""
        # puts RedisUtil.get_client_attributes(username)
  
        puts ""
      end
    end
  end
end