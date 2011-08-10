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
      log_and_continue do
        log "*"*10 + "Checking user #{user}"
        opp_data = HealthCheckUtil.get_rhosync_source_data(user, 'Opportunity')
        opp_ids_rhosync = opp_data.keys
    
        expiring_opp_ids = CleanOldOpportunityData.get_expired_opportunities(opp_data, -1).map{|key,value| key} # gather list of opps that have already expired or will expire within 24 hours
    
        opp_ids_crm = HealthCheckUtil.get_crm_data('opportunity', user, HealthCheckUtil.credentials[user]).map { |i| i['opportunityid'] }  

        opp_ids_in_rhosync_not_crm = opp_ids_rhosync.reject { |id| opp_ids_crm.include?(id) or expiring_opp_ids.include?(id) }
        log "Opportunities in Rhosync not in CRM: #{opp_ids_in_rhosync_not_crm.count}"
        log "#{opp_ids_in_rhosync_not_crm.inspect}"
        
        opp_ids_in_crm_not_rhosync = opp_ids_crm.reject { |id| opp_ids_rhosync.include?(id) }
        log "Opportunities in CRM not in Rhosync: #{opp_ids_in_crm_not_rhosync.count}"
        log "#{opp_ids_in_crm_not_rhosync.inspect}"


        user_passed = !HealthCheckUtil.source_initialized?(user, 'opportunity') || (opp_ids_in_rhosync_not_crm.count == 0 && opp_ids_in_crm_not_rhosync.count == 0)        
        
        log "Result: #{user_passed ? 'PASS' : 'FAIL'}"
        
        @results[user] = {:passed => user_passed, :extra_rhosync_opps => opp_ids_in_rhosync_not_crm, :extra_crm_opps => opp_ids_in_crm_not_rhosync}
      end
    end
  end
  
  def result_summary
    total_user_count = HealthCheckUtil.users.count
    super + " #{agent_failures.count} agents and #{other_failures.count} others failed out of #{total_user_count} total users."
  end
  
  def result_details
    details = failures.sort{|x,y| x[0] <=> y[0]}.reduce([]){|sum,(user,result)|
      sum << "#{user} had #{result[:extra_rhosync_opps].count} extra opps in RhoSync and #{result[:extra_crm_opps].count} extra opps in CRM."
      sum
    }.join("\n")
    super + "\n#{details}"
  end
end