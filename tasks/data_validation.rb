class DataValidation
  
  def self.validate(username=nil)
    
    puts "Environment: #{CONFIG[:env]}"
    
    rhoconnectApi = RhoconnectApiSession.new CONFIG[:env]
     
    users = []
    if username.nil?
      users = rhoconnectApi.get_all_users
    else
      users << username
    end
    
    #get user passwords to use during REST calls to the Proxy
    passwords = Hash.new
    users.each do |user|
      encrypted_password = rhoconnectApi.get_db_doc("username:#{user}:password", 'string')
      passwords[user] = Crypto.decrypt(encrypted_password)
    end
        
    users.each do |user|
    
      puts "\n\n" + "*"*10 + "User #{user}:\n"
    
      #1.compare Contact data
      puts "\n"
      
      contact_docs = rhoconnectApi.list_source_docs('Contact', user)      
      contact_data = rhoconnectApi.get_db_doc( contact_docs['md'] )
      contact_ids_rhoconnect = contact_data.keys
      puts "Contacts in Rhoconnect: " + contact_ids_rhoconnect.count.to_s
            
      res = RestClient.post("#{CONFIG[:crm_path]}/contact",
        { :username => user, 
          :password => passwords[user] },
          :content_type => :json
      ).body
      contact_ids_crm = JSON.parse(res).map { |i| i['contactid'] }  
      puts "Contacts in CRM: #{contact_ids_crm.count}"  
      
      contact_ids_in_rhoconnect_not_crm = contact_ids_rhoconnect.reject do |id|
        contact_ids_crm.include?(id)
      end
      puts "Contacts in Rhoconnect not in CRM: #{contact_ids_in_rhoconnect_not_crm.count}"
      puts contact_ids_in_rhoconnect_not_crm.inspect unless contact_ids_in_rhoconnect_not_crm.count == 0
  
      contact_ids_in_crm_not_rhoconnect = contact_ids_crm.reject do |id|
        contact_ids_rhoconnect.include?(id)
      end
      puts "Contacts in CRM not in Rhoconnect: #{contact_ids_in_crm_not_rhoconnect.count}"
      puts contact_ids_in_crm_not_rhoconnect.inspect unless contact_ids_in_crm_not_rhoconnect.count == 0
      
      
      #2.compare Opportunity data
      puts "\n"
      
      opp_docs = rhoconnectApi.list_source_docs('Opportunity', user)      
      opp_data = rhoconnectApi.get_db_doc( opp_docs['md'] )
      opp_ids_rhoconnect = opp_data.keys
      puts "Opportunities in Rhoconnect: " + opp_ids_rhoconnect.count.to_s
            
      res = RestClient.post("#{CONFIG[:crm_path]}/opportunity",
        { :username => user, 
          :password => passwords[user] },
          :content_type => :json
      ).body
      opp_ids_crm = JSON.parse(res).map { |i| i['opportunityid'] }  
      puts "Opportunities in CRM: #{opp_ids_crm.count}"  
      
      opp_ids_in_rhoconnect_not_crm = opp_ids_rhoconnect.reject do |id|
        opp_ids_crm.include?(id)
      end
      puts "Opportunities in Rhoconnect not in CRM: #{opp_ids_in_rhoconnect_not_crm.count}"
      puts opp_ids_in_rhoconnect_not_crm.inspect unless opp_ids_in_rhoconnect_not_crm.count == 0
  
      opp_ids_in_crm_not_rhoconnect = opp_ids_crm.reject do |id|
        opp_ids_rhoconnect.include?(id)
      end
      puts "Opportunities in CRM not in Rhoconnect: #{opp_ids_in_crm_not_rhoconnect.count}"
      puts opp_ids_in_crm_not_rhoconnect.inspect unless opp_ids_in_crm_not_rhoconnect.count == 0
      
      
      #3.Integrity check for Rhoconnect data
      puts "\n"

      opps_without_contacts = opp_ids_rhoconnect.reject do |id|
        contact_ids_rhoconnect.include?( opp_data[id]['contact_id'] )
      end
      puts "Opportunities in Rhoconnect with no attached contacts: #{opps_without_contacts.count}"
      puts opps_without_contacts.inspect unless opps_without_contacts.count == 0
            
      
      #4.Device key check
      puts "\n"
      
      user_devices = rhoconnectApi.get_user_devices(user)
      next if user_devices.empty?
      
      puts "Devices in Rhoconnect: #{user_devices.count}"
      
      devices_missing_pin = []
      user_devices.each do |device_id|
        device_pin = rhoconnectApi.get_device_params(device_id).select{ |k| k['name'] == 'device_pin' }.first        
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
