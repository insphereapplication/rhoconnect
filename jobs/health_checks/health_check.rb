app_path = File.expand_path(File.join(File.dirname(__FILE__))) 
require "#{app_path}/../../jobs/rhoconnect_resque_job"
require 'ap'

class HealthCheck
  include RhoconnectResqueJob
  
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
  
  def log_run
    InsiteLogger.info "$"*25 + "  Starting #{@friendly_name} check  " + "$"*25
  end
end

class HealthCheckUtil
  include RhoconnectResqueJob
  
  class << self
    def sync_status
      @sync_status ||= rhoconnect_api.get_sync_status("*")
    end
    
    def users
      @users ||= rhoconnect_api.get_all_users
    end
    
    def credentials
      @credentials ||= users.reduce({}){ |sum,user| sum[user] = rhoconnect_api.get_user_password(user); sum }
    end
      
    def get_rhoconnect_source_data(user, docname)
      docs = rhoconnect_api.list_source_docs(docname, user)      
      data = rhoconnect_api.get_db_doc( docs['md'] )
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

module AgentFailureFilters
  def failures
    @failures ||= @results.reject{|key,value| value[:passed] }
  end
  
  def agent_failures
    @agent_failures ||= failures.reject{|key,value| key[/^[aA][0-9]{5}$/].nil?}
  end
  
  def other_failures
    @other_failures ||= failures.reject{|key,value| agent_failures.include?(key)}
  end
  
  def passed
     (agent_failures.count == 0)
  end
end