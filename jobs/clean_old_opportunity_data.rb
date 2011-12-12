require File.expand_path("#{File.dirname(__FILE__)}/../jobs/rhosync_resque_job")
require 'time'

class CleanOldOpportunityData
  MAX_OPEN_OPPORTUNITY_AGE_IN_DAYS = 61
  MAX_WON_OPPORTUNITY_AGE_IN_DAYS = 91
  CLOSED_ACTIVITY_AGE_IN_DAYS = 15
  OPEN_SCHEDULED_ACTIVITY_AGE_IN_DAYS = 61
  OPEN_UNSCHEDULED_ACTIVTY_AGE_IN_DAYS = 61
  TERMINATED_POLICES_AGE_IN_DAYS = 31
  SECONDS_IN_A_DAY = 86400
  @queue = :clean_old_opportunity_data

  include RhosyncResqueJob
  
  class << self
    def get_doc_ids(doc)
      doc.map{|item| item[0]}
    end
    
    def perform
      InsiteLogger.info "Initiating resque job CleanOldOpportunityData..."
      ExceptionUtil.rescue_and_continue do
        
        users.each do |user|
          begin
            InsiteLogger.info("*"*10 + "starting cleanup job for #{user}")
            opportunities =  rhosync_api.get_db_doc("source:application:#{user}:Opportunity:md")
            activities =  rhosync_api.get_db_doc("source:application:#{user}:Activity:md")
            contacts = rhosync_api.get_db_doc("source:application:#{user}:Contact:md")
            policies = rhosync_api.get_db_doc("source:application:#{user}:Policy:md")
          
            # find the expired Opportunities
            old_opportunities = get_expired_opportunities(opportunities)          
            old_opportunity_ids = get_doc_ids(old_opportunities)
          
            # find reassign Opportunities
            reassigned_opportunites = get_reassigned_opportunities(opportunities, user)
            reassigned_opportunity_ids = get_doc_ids(reassigned_opportunites)
  
            # now find the activities that are expired
            old_activities = get_expired_activities(activities)
            old_activity_ids = get_doc_ids(old_activities)
            #old_activity_ids =[]
          
            # get a set of the remaining opportunities so we don't reject a contact that may be related to more than one opportunity
            current_opportunities = opportunities.reject{|k,v| old_opportunity_ids.include?(k) || reassigned_opportunity_ids.include?(k) }
            current_activities = activities.reject{|k,v| old_activity_ids.include?(k)}
            
            # find policies that are expired
            old_policies = get_expired_policies(policies)
            old_policies_ids = get_doc_ids(old_policies)
            current_policies = policies.reject{|k,v| old_policies_ids.include?(k)}
          
            # look for contacts on expired activities and expired opportunities that are eligible to be deleted
            old_contacts = get_expired_contacts(current_opportunities, current_activities, contacts, current_policies)
            old_contact_ids = get_doc_ids(old_contacts)

            InsiteLogger.info(:format_and_join => ["Deleting for user #{user}: old_opps: ",old_opportunity_ids,", reassign_opps: ",reassigned_opportunity_ids, ", contacts: ",old_contact_ids,", activities: ",old_activity_ids, ", policies: ", old_policies_ids])
          
            # delete expired records for all models 
            rhosync_api.push_deletes('Activity',user,old_activity_ids) unless old_activity_ids.empty?
            rhosync_api.push_deletes('Opportunity',user,old_opportunity_ids) unless old_opportunity_ids.empty?
            rhosync_api.push_deletes('Opportunity',user,reassigned_opportunity_ids) unless reassigned_opportunity_ids.empty?
            rhosync_api.push_deletes('Contact',user,old_contact_ids) unless old_contact_ids.empty?
            rhosync_api.push_deletes('Policy',user,old_policies_ids) unless old_policies_ids.empty?
          rescue Exception => e
            ExceptionUtil.print_exception(e)
            InsiteLogger.info("*"*10 + "exception occured during cleanup job for #{user}")
          end    
        end
      end
    end 
  
    def get_expired_activities(activities)
      activities.reject do |key, activity|
      #InsiteLogger.info( "!!!!!! working on activity: #{key}")
        begin
          case activity['statecode']
          when "Completed"
           # InsiteLogger.info( "1. Is #{activity['statecode']} activity #{key} valid: #{Time.parse(activity['actualend']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*CLOSED_ACTIVITY_AGE_IN_DAYS}")
            Time.parse(activity['actualend']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*CLOSED_ACTIVITY_AGE_IN_DAYS
          when "Open", "Scheduled"
            if activity["scheduledend"].blank?
            #  InsiteLogger.info( "2. Is #{activity['statecode']} activity #{key} valid: #{Time.parse(activity['createdon']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*OPEN_UNSCHEDULED_ACTIVTY_AGE_IN_DAYS}")
              Time.parse(activity['createdon']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*OPEN_UNSCHEDULED_ACTIVTY_AGE_IN_DAYS
            else
             # InsiteLogger.info( "3. Is #{activity['statecode']} activity #{key} valid: #{Time.parse(activity['scheduledend']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*OPEN_SCHEDULED_ACTIVITY_AGE_IN_DAYS}")
              Time.parse(activity['scheduledend']).to_i >= Time.now.to_i - SECONDS_IN_A_DAY*OPEN_SCHEDULED_ACTIVITY_AGE_IN_DAYS
            end    
          else
            #  InsiteLogger.info("Missing activity statecode: #{activity['statecode']} activity #{key}" )
              true
          end
        rescue Exception => e
          ExceptionUtil.print_exception(e)
          InsiteLogger.info( "4. Is #{activity['statecode']} activity #{key} expired: True")
          false
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
    
    def get_expired_opportunities(opportunities, offset_days=0)
      opportunities.select do |key, opp|
        expired = false
        begin
          case opp['statecode']
          when "Won"
            check_date = opp['actualclosedate'] || opp['createdon']
            expired = Time.now.to_i - Time.parse(check_date).to_i > (MAX_WON_OPPORTUNITY_AGE_IN_DAYS + offset_days)*SECONDS_IN_A_DAY
          when "Open"
            check_date = opp['cssi_lastactivitydate'] || opp['createdon'] 
            expired = Time.now.to_i - Time.parse(check_date).to_i > (MAX_OPEN_OPPORTUNITY_AGE_IN_DAYS + offset_days)*SECONDS_IN_A_DAY  
          else
            # For all other state codes (i.e. Lost), mark as expired
            expired = true
          end
        rescue
          # If time parsing or other logic fails, assume expired
          expired = true
        end
        expired
      end
    end
    
    def get_expired_policies(policies, offset_days=0)
      policies.select do |key, pol|
        expired = false
        begin
          case pol['statuscode']
          when "Terminated"
            check_date = pol['cssi_statusdate'] 
            #InsiteLogger.info( "1. Is #{pol['statuscode']} policy #{key} expired: #{Time.now.to_i - Time.parse(check_date).to_i > (TERMINATED_POLICES_AGE_IN_DAYS + offset_days)*SECONDS_IN_A_DAY}")
            expired = Time.now.to_i - Time.parse(check_date).to_i > (TERMINATED_POLICES_AGE_IN_DAYS + offset_days)*SECONDS_IN_A_DAY
          else
            # For all other state codes (i.e. Lost), mark as expired
            #InsiteLogger.info(" #{pol['statuscode']} policy #{key} is not TERMINATED and not expired")
            expired = false
          end
        rescue Exception => e
          # If time parsing or other logic fails, assume expired
            ExceptionUtil.print_exception(e)
            InsiteLogger.info( "error on policy #{key}")
          expired = false
        end
        expired
      end
    end
    
    def get_reassigned_opportunities(opportunities, user)
       crm_user_id = rhosync_api.get_user_crm_id("#{user}")
       opportunities.reject do |key, opp|
         opp["ownerid"].blank? || opp["ownerid"] == crm_user_id
       end 
    end
      
  end
end
