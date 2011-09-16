class DataValidation
  
  def self.validate(username=nil)
    
    puts "Environment: #{CONFIG[:env]}"
    
    rhosyncApi = RhosyncApiSession.new CONFIG[:env]
     
    users = []
    if username.nil?
      users = rhosyncApi.get_all_users
    else
      users << username
    end
    
    #get user passwords to use during REST calls to the Proxy
    passwords = Hash.new
    users.each do |user|
      encrypted_password = rhosyncApi.get_db_doc("username:#{user}:password", 'string')
      passwords[user] = Crypto.decrypt(encrypted_password)
    end
        
    users.each do |user|
    
      puts "\n\n" + "*"*10 + "User #{user}:\n"
    
      #1.compare Contact data
      puts "\n"
      
      contact_docs = rhosyncApi.list_source_docs('Contact', user)      
      contact_data = rhosyncApi.get_db_doc( contact_docs['md'] )
      contact_ids_rhosync = contact_data.keys
      puts "Contacts in Rhosync: " + contact_ids_rhosync.count.to_s
            
      res = RestClient.post("#{CONFIG[:crm_path]}/contact",
        { :username => user, 
          :password => passwords[user] },
          :content_type => :json
      ).body
      contact_ids_crm = JSON.parse(res).map { |i| i['contactid'] }  
      puts "Contacts in CRM: #{contact_ids_crm.count}"  
      
      contact_ids_in_rhosync_not_crm = contact_ids_rhosync.reject do |id|
        contact_ids_crm.include?(id)
      end
      puts "Contacts in Rhosync not in CRM: #{contact_ids_in_rhosync_not_crm.count}"
      puts contact_ids_in_rhosync_not_crm.inspect unless contact_ids_in_rhosync_not_crm.count == 0
  
      contact_ids_in_crm_not_rhosync = contact_ids_crm.reject do |id|
        contact_ids_rhosync.include?(id)
      end
      puts "Contacts in CRM not in Rhosync: #{contact_ids_in_crm_not_rhosync.count}"
      puts contact_ids_in_crm_not_rhosync.inspect unless contact_ids_in_crm_not_rhosync.count == 0
      
      
      #2.compare Opportunity data
      puts "\n"
      
      opp_docs = rhosyncApi.list_source_docs('Opportunity', user)      
      opp_data = rhosyncApi.get_db_doc( opp_docs['md'] )
      opp_ids_rhosync = opp_data.keys
      puts "Opportunities in Rhosync: " + opp_ids_rhosync.count.to_s
            
      res = RestClient.post("#{CONFIG[:crm_path]}/opportunity",
        { :username => user, 
          :password => passwords[user] },
          :content_type => :json
      ).body
      opp_ids_crm = JSON.parse(res).map { |i| i['opportunityid'] }  
      puts "Opportunities in CRM: #{opp_ids_crm.count}"  
      
      opp_ids_in_rhosync_not_crm = opp_ids_rhosync.reject do |id|
        opp_ids_crm.include?(id)
      end
      puts "Opportunities in Rhosync not in CRM: #{opp_ids_in_rhosync_not_crm.count}"
      puts opp_ids_in_rhosync_not_crm.inspect unless opp_ids_in_rhosync_not_crm.count == 0
  
      opp_ids_in_crm_not_rhosync = opp_ids_crm.reject do |id|
        opp_ids_rhosync.include?(id)
      end
      puts "Opportunities in CRM not in Rhosync: #{opp_ids_in_crm_not_rhosync.count}"
      puts opp_ids_in_crm_not_rhosync.inspect unless opp_ids_in_crm_not_rhosync.count == 0
      
      
      #3.Integrity check for Rhosync data
      puts "\n"

      opps_without_contacts = opp_ids_rhosync.reject do |id|
        contact_ids_rhosync.include?( opp_data[id]['contact_id'] )
      end
      puts "Opportunities in Rhosync with no attached contacts: #{opps_without_contacts.count}"
      puts opps_without_contacts.inspect unless opps_without_contacts.count == 0
            
      
      #4.Device key check
      puts "\n"
      
      user_devices = rhosyncApi.get_user_devices(user)
      next if user_devices.empty?
      
      puts "Devices in Rhosync: #{user_devices.count}"
      
      devices_missing_pin = []
      user_devices.each do |device_id|
        device_pin = rhosyncApi.get_device_params(device_id).select{ |k| k['name'] == 'device_pin' }.first        
        devices_missing_pin << device_id if device_pin.nil? || (!device_pin.nil? && device_pin['value'].nil?)      
      end
      
      if devices_missing_pin.count > 0
        puts "#{devices_missing_pin.count} of #{user_devices.count} devices have no PIN"
        devices_missing_pin.each do |id| puts "  #{id}" end
      else
        puts "All #{user_devices.count} devices have a PIN"  
      end      
      
    end    
    puts "\n\n*************Done!\n\n"      
  end
  
end
