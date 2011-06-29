require File.expand_path("#{File.dirname(__FILE__)}/../jobs/rhosync_resque_job")

class CleanOldOpportunityData
  include RhosyncResqueJob
  MAX_OPEN_OPPORTUNITY_AGE_IN_DAYS = 60
  MAX_WON_OPPORTUNITY_AGE_IN_DAYS = 90
  @queue = :clean_old_opportunity_data
  
  class << self
    def perform
      InsiteLogger.info "Initiating resque job CleanOldOpportunityData..."
      ExceptionUtil.rescue_and_reraise do
        get_master_docs(users).each do |user, opportunities, activities, contacts, policies|
          # find the expired Opportunities
          old_opportunities = get_expired_opportunities(opportunities)  
          old_opp_keys = old_opportunities.keys
          InsiteLogger.info "Deleting old opportunities, activities, contacts for user #{user}"
          InsiteLogger.info "Old opps are: #{old_opp_keys.inspect}"
          
          # now find the activities that are owned by the expired Opportunties
          old_activities = get_expired_activities(old_opp_keys, activities)
          InsiteLogger.info "Old activities are: #{old_activities.keys.inspect}"
          
          # get a set of the remaining opportunities so we don't reject a contact that may be related to more than one opportunity
          current_opportunities = opportunities.reject{|k,v| old_opp_keys.include?(k) }
          old_contacts = get_expired_contacts(current_opportunities, contacts, policies)
          InsiteLogger.info "Old contacts are: #{old_contacts.keys.inspect}"
          
          # delete expired records for both models
          Rhosync::Store.delete_data("source:application:#{user}:Activity:md", old_activities)
          Rhosync::Store.delete_data("source:application:#{user}:Opportunity:md", old_opportunities)
          Rhosync::Store.delete_data("source:application:#{user}:Contact:md", old_contacts)
        end
      end
    end 
    
    def get_expired_activities(old_opp_keys, activities)
      activities.select do |key, activity|
         activity['parent_type'] == 'opportunity' && old_opp_keys.include?(activity['parent_id'])
      end
    end
    
    def get_expired_contacts(current_opportunities, contacts, policies)
      current_opportunities_contact_ids = current_opportunities.map{|a| a['contact_id']}
      policy_contact_ids = policies.map{|k,v| v['contact_id']}
      contacts.select do |key, contact|
        !current_opportunities_contact_ids.include?(key) && !policy_contact_ids.include?(key)
      end
    end
    
    def get_expired_opportunities(opportunities)
      opportunities.select do |key, opp| 
        begin
          check_date = opp['cssi_lastactivitydate'] || opp['createdon']
          case opp['statecode']
          when "Won"
            (Time.now - Time.parse(check_date)).to_days > MAX_WON_OPPORTUNITY_AGE_IN_DAYS
          else
            (Time.now - Time.parse(check_date)).to_days > MAX_OPEN_OPPORTUNITY_AGE_IN_DAYS  
          end           
        rescue 
          true
        end
      end
    end
  
    def get_master_docs(users)
       users.map do |user| 
        [ 
          user, 
          Rhosync::Store.get_data("source:application:#{user}:Opportunity:md"),
          Rhosync::Store.get_data("source:application:#{user}:Activity:md"),
          Rhosync::Store.get_date("source:application:#{user}:Contact:md"),
          Rhosync::Store.get_date("source:application:#{user}:Policy:md")
        ]
      end
    end
  end
end
