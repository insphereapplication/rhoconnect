class OpportunityIntegrityCheck < HealthCheck
  include AgentFailureFilters
  
  def initialize
    super("Opportunity integrity")
    @results = {}
    run
  end
  
  def run
    log_run
    HealthCheckUtil.users.each do |user|
      ExceptionUtil.rescue_and_continue do        
        InsiteLogger.info "*"*10 + "Checking user #{user}"
        
        opportunities = HealthCheckUtil.get_rhoconnect_source_data(user, 'Opportunity')
        contacts = HealthCheckUtil.get_rhoconnect_source_data(user, 'Contact')
        
        opps_without_contacts = opportunities.reject{|id,opp| 
          contacts.include?(opp['contact_id'])
        }
        
        InsiteLogger.info "Opps without contacts: #{opps_without_contacts.map{|id,opp| id}.inspect}"
        
        user_passed = !HealthCheckUtil.source_initialized?(user, 'opportunity') || opps_without_contacts.count == 0
        
        InsiteLogger.info "Result: #{user_passed ? 'PASS' : 'FAIL'}"
        
        @results[user] = {:passed => user_passed, :opps_without_contacts => opps_without_contacts}
      end
    end
  end
  
  def result_summary
    total_user_count = HealthCheckUtil.users.count
    super + " #{agent_failures.count} agents and #{other_failures.count} others failed out of #{total_user_count} total users."
  end
  
  def result_details
    details = failures.sort{|x,y| x[0] <=> y[0]}.reduce([]){|sum,(user,result)|
      sum << "#{user} had #{result[:opps_without_contacts].count} opportunities with no contact."
      sum
    }.join("\n")
    super + "\n#{details}"
  end
end