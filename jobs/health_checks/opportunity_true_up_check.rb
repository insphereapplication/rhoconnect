class OpportunityTrueUpCheck < HealthCheck
  include AgentFailureFilters
  
  def initialize
    super("Opportunity true-up")
    @results = {}
    run
  end
  
  def run
    log_run
    HealthCheckUtil.users.each do |user|
      ExceptionUtil.rescue_and_continue do
        InsiteLogger.info "*"*10 + "Checking user #{user}"
        opp_data = HealthCheckUtil.get_rhoconnect_source_data(user, 'Opportunity')
        opp_ids_rhoconnect = opp_data.keys
    
        expiring_opp_ids = CleanOldOpportunityData.get_expired_opportunities(opp_data, -1).map{|key,value| key} # gather list of opps that have already expired or will expire within 24 hours
    
        opp_ids_crm = HealthCheckUtil.get_crm_data('opportunity', user, HealthCheckUtil.credentials[user]).map { |i| i['opportunityid'] }  

        opp_ids_in_rhoconnect_not_crm = opp_ids_rhoconnect.reject { |id| opp_ids_crm.include?(id) or expiring_opp_ids.include?(id) }
        InsiteLogger.info "Opportunities in Rhoconnect not in CRM: #{opp_ids_in_rhoconnect_not_crm.count}"
        InsiteLogger.info "#{opp_ids_in_rhoconnect_not_crm.inspect}"
        
        opp_ids_in_crm_not_rhoconnect = opp_ids_crm.reject { |id| opp_ids_rhoconnect.include?(id) }
        InsiteLogger.info "Opportunities in CRM not in Rhoconnect: #{opp_ids_in_crm_not_rhoconnect.count}"
        InsiteLogger.info "#{opp_ids_in_crm_not_rhoconnect.inspect}"


        user_passed = !HealthCheckUtil.source_initialized?(user, 'opportunity') || (opp_ids_in_rhoconnect_not_crm.count == 0 && opp_ids_in_crm_not_rhoconnect.count == 0)        
        
        InsiteLogger.info "Result: #{user_passed ? 'PASS' : 'FAIL'}"
        
        @results[user] = {:passed => user_passed, :extra_rhoconnect_opps => opp_ids_in_rhoconnect_not_crm, :extra_crm_opps => opp_ids_in_crm_not_rhoconnect}
      end
    end
  end
  
  def result_summary
    total_user_count = HealthCheckUtil.users.count
    super + " #{agent_failures.count} agents and #{other_failures.count} others failed out of #{total_user_count} total users."
  end
  
  def result_details
    details = failures.sort{|x,y| x[0] <=> y[0]}.reduce([]){|sum,(user,result)|
      sum << "#{user} had #{result[:extra_rhoconnect_opps].count} extra opps in RhoConnect and #{result[:extra_crm_opps].count} extra opps in CRM."
      sum
    }.join("\n")
    super + "\n#{details}"
  end
end