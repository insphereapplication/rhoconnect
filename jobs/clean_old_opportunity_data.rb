require File.expand_path("#{File.dirname(__FILE__)}/../jobs/rhosync_resque_job")
require 'time'

class CleanOldOpportunityData
  MAX_OPEN_OPPORTUNITY_AGE_IN_DAYS = 61
  MAX_WON_OPPORTUNITY_AGE_IN_DAYS = 91
  @queue = :clean_old_opportunity_data
  
  class << self
    include RhosyncResqueJob
    
    def get_doc_ids(doc)
      doc.map{|item| item[0]}
    end
    
    def perform
      InsiteLogger.info "Initiating resque job CleanOldOpportunityData..."
      ExceptionUtil.rescue_and_reraise do
        
        get_master_docs(users).each do |user, opportunities, activities, contacts, policies|

          # find the expired Opportunities
          old_opportunities = get_expired_opportunities(opportunities)          
          old_opportunity_ids = get_doc_ids(old_opportunities)
        
          # now find the activities that are owned by the expired Opportunties
          old_activities = get_expired_activities(old_opportunity_ids, activities)
          old_activity_ids = get_doc_ids(old_activities)
          
          # get a set of the remaining opportunities so we don't reject a contact that may be related to more than one opportunity
          current_opportunities = opportunities.reject{|k,v| old_opportunity_ids.include?(k) }
          old_contacts = get_expired_contacts(current_opportunities, contacts, policies)
          old_contact_ids = get_doc_ids(old_contacts)

          
          InsiteLogger.info(:format_and_join => ["Deleting for user #{user}: opps ",old_opportunity_ids,", contacts: ",old_contact_ids,", activities: ",old_activity_ids])
          
          # delete expired records for all models 
          rhosync_api.push_deletes('Activity',user,old_activity_ids) unless old_activity_ids.empty?
          rhosync_api.push_deletes('Opportunity',user,old_opportunity_ids) unless old_opportunity_ids.empty?
          rhosync_api.push_deletes('Contact',user,old_contact_ids) unless old_contact_ids.empty?
        end
      end
    end 
    
    def get_expired_activities(old_opp_ids, activities)
      activities.select do |key, activity|
         activity['parent_type'] == 'opportunity' && old_opp_ids.include?(activity['parent_id'])
      end
    end
    
    def get_expired_contacts(current_opportunities, contacts, policies)
      current_opportunities_contact_ids = current_opportunities.map{|k,v| v['contact_id']}
      policy_contact_ids = policies.map{|k,v| v['contact_id']}
      contacts.select do |key, contact|
        !current_opportunities_contact_ids.include?(key) && !policy_contact_ids.include?(key)
      end
    end
    
    def get_expired_opportunities(opportunities, offset_days=0)
      opportunities.select do |key, opp|
        begin
          check_date = opp['cssi_lastactivitydate'] || opp['createdon']                                        
          case opp['statecode']
          when "Won"
            Time.now.to_i - Time.parse(check_date).to_i > (MAX_WON_OPPORTUNITY_AGE_IN_DAYS + offset_days)*86400
          else
            Time.now.to_i - Time.parse(check_date).to_i > (MAX_OPEN_OPPORTUNITY_AGE_IN_DAYS + offset_days)*86400  
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
          rhosync_api.get_db_doc("source:application:#{user}:Opportunity:md"),
          rhosync_api.get_db_doc("source:application:#{user}:Activity:md"),
          rhosync_api.get_db_doc("source:application:#{user}:Contact:md"),
          rhosync_api.get_db_doc("source:application:#{user}:Policy:md")
        ]
      end
    end
  end
end
