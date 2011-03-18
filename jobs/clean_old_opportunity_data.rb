require 'rhosync'

class CleanOldOpportunityData
  MAX_OPPORTUNITY_AGE_IN_DAYS = 3
  
  @queue = :clean_old_opportunity_data
  @redis = Redis.connect(:url => ENV['REDIS'])
  # @redis = Redis.new
  
  Rhosync::Store.db # need to call this to initialize the @db member of Store
  # Rhosync::Store.extend(Rhosync)
  
  class << self
    def users
      userkeys = @redis.keys('user:*:rho__id')
      userkeys.map{|u| @redis.get(u)}
    end
    
    def perform
      get_master_docs(users).each do |user, opportunities, activities|
        # find the expired Opportunities
        old_opportunities = get_expired_opportunities(opportunities)  
        old_opp_keys = old_opportunities.map{|k,v| k}
      
        # now find the activities that are owned by the expired Opportunties
        old_activities = get_expired_activities(old_opp_keys, activities)
      
        # delete expired records for both models
        Rhosync::Store.delete_data("source:application:#{user}:Activity:md", old_activities)
        Rhosync::Store.delete_data("source:application:#{user}:Opportunity:md", old_opportunities)
      end
    end 
    
    def get_expired_activities(old_opp_keys, activities)
      activities.select do |key, activity|
         activity['parent_type'] == 'opportunity' && old_opp_keys.include?(activity['parent_id'])
      end
    end
    
    def get_expired_opportunities(opportunities)
      opportunities.select do |key, opp| 
        begin
          check_date = opp['cssi_lastactivitydate'] || opp['createdon']
          (Time.now - Time.parse(check_date)).to_days > MAX_OPPORTUNITY_AGE_IN_DAYS 
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
          Rhosync::Store.get_data("source:application:#{user}:Activity:md")
        ]
      end
    end
  end
end
