class PolicyIntegrityCheck < HealthCheck
  include AgentFailureFilters
  
  def initialize
    super("Policy integrity")
    @results = {}
    run
  end
  
  def run
    log_run
    HealthCheckUtil.users.each do |user|
      ExceptionUtil.rescue_and_continue do        
        InsiteLogger.info "*"*10 + "Checking user #{user}"
        
        policies = HealthCheckUtil.get_rhoconnect_source_data(user, 'Policy')
        contacts = HealthCheckUtil.get_rhoconnect_source_data(user, 'Contact')
        
        policies_without_contacts = policies.reject{|id,policy| 
          policy['contact_id'].nil? || contacts.include?(policy['contact_id'])
        }
        
        InsiteLogger.info "Policies without contacts: #{policies_without_contacts.keys.inspect}"
        
        user_passed = (policies_without_contacts.count == 0)
        
        @results[user] = {:passed => user_passed, :policies_without_contacts => policies_without_contacts}
      end
    end
  end
  
  def result_summary
    total_user_count = HealthCheckUtil.users.count
    super + " #{agent_failures.count} agents and #{other_failures.count} others failed out of #{total_user_count} total users."
  end
  
  def result_details
    details = failures.sort{|x,y| x[0] <=> y[0]}.reduce([]){|sum,(user,result)|
      sum << "#{user} had #{result[:policies_without_contacts].count} policies with no contact."
      sum
    }.join("\n")
    super + "\n#{details}"
  end
end