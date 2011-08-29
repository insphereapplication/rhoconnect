require File.expand_path("#{File.dirname(__FILE__)}/../jobs/rhosync_resque_job")
require 'time'

class CleanOldOpportunityData
  MAX_OPEN_OPPORTUNITY_AGE_IN_DAYS = 60
  MAX_WON_OPPORTUNITY_AGE_IN_DAYS = 90
  CLOSED_ACTIVITY_AGE_IN_DAYS = 14
  OPEN_SCHEDULED_ACTIVITY_AGE_IN_DAYS = 60
  OPEN_UNSCHEDULED_ACTIVTY_AGE_IN_DAYS = 60
  SECONDS_IN_A_DAY = 86400
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
        
          # now find the activities that are expired
          old_activities = get_expired_activities(activities)
          old_activity_ids = get_doc_ids(old_activities)
          
          # get a set of the remaining opportunities so we don't reject a contact that may be related to more than one opportunity
          current_opportunities = opportunities.reject{|k,v| old_opportunity_ids.include?(k) }
          current_activities = activities.reject{|k,v| old_activity_ids.include?(k)}
          
          # look for contacts on expired activities and expired opportunities that are eligible to be deleted
          old_contacts = get_expired_contacts(current_opportunities, current_activities, contacts, policies)
          old_contact_ids = get_doc_ids(old_contacts)

          
          InsiteLogger.info(:format_and_join => ["Deleting for user #{user}: opps ",old_opportunity_ids,", contacts: ",old_contact_ids,", activities: ",old_activity_ids])
          
          # delete expired records for all models 
          rhosync_api.push_deletes('Activity',user,old_activity_ids) unless old_activity_ids.empty?
          rhosync_api.push_deletes('Opportunity',user,old_opportunity_ids) unless old_opportunity_ids.empty?
          rhosync_api.push_deletes('Contact',user,old_contact_ids) unless old_contact_ids.empty?
          
        end
      end
    end 
  
    def get_expired_activities(activities)
      activities.reject do |key, activity|
        begin
          case activity['statecode']
          when "Completed"
            InsiteLogger.info( "1. Is #{activity['statecode']} activity #{key} valid: #{Time.parse(activity['actualend']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*CLOSED_ACTIVITY_AGE_IN_DAYS}")
            Time.parse(activity['actualend']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*CLOSED_ACTIVITY_AGE_IN_DAYS
          when "Open"
            if activity["scheduledend"].blank?
              InsiteLogger.info( "2. Is #{activity['statecode']} activity #{key} valid: #{Time.parse(activity['createdon']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*OPEN_UNSCHEDULED_ACTIVTY_AGE_IN_DAYS}")
              Time.parse(activity['createdon']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*OPEN_UNSCHEDULED_ACTIVTY_AGE_IN_DAYS
            else
              InsiteLogger.info( "3. Is #{activity['statecode']} activity #{key} valid: #{Time.parse(activity['scheduledend']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*OPEN_SCHEDULED_ACTIVITY_AGE_IN_DAYS}")
              Time.parse(activity['scheduledend']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*OPEN_SCHEDULED_ACTIVITY_AGE_IN_DAYS
            end    
          end
        rescue Exception => e
          ExceptionUtil.print_exception(e)
          InsiteLogger.info( "4. Is #{activity['statecode']} activity #{key} expired: True")
          true
        end    
      end
     end
    
    def get_expired_contacts(current_opportunities, current_activities, contacts, policies)
      current_opportunities_contact_ids = current_opportunities.map{|k,v| v['contact_id']}

      current_activities_regarding_contacts = current_activities.select do |key,activity|
        activity["parent_type"] == 'contact'
      end

      current_activities_contact_ids = current_activities_regarding_contacts.map{|k,v| v['parent_id']}

        policy_contact_ids = policies.map{|k,v| v['contact_id']}

      contacts.select do |key, contact|
        !current_opportunities_contact_ids.include?(key) && !policy_contact_ids.include?(key) &&
         !current_activities_contact_ids.include?(key)
      end

    end
    
    def get_expired_opportunities(opportunities)
      opportunities.select do |key, opp|
        begin
          check_date = opp['cssi_lastactivitydate'] || opp['createdon']                                        
          case opp['statecode']
          when "Won"
            Time.now.to_i - Time.parse(check_date).to_i > MAX_WON_OPPORTUNITY_AGE_IN_DAYS*SECONDS_IN_A_DAY
          else
            Time.now.to_i - Time.parse(check_date).to_i > MAX_OPEN_OPPORTUNITY_AGE_IN_DAYS*SECONDS_IN_A_DAY  
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
