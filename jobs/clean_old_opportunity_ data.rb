require 'rhosync'

class CleanOldOpportunityData
  
  @queue = :clean_old_opportunity_data
  @redis = Redis.new
  
  def self.perform
    Rhosync::Store.db # need to call this to initialize the @db member of Store
    userkeys = @redis.keys('user:*:rho__id')
    users = userkeys.map{|u| @redis.get(u)}.reject{|u| u == 'rhoadmin'}
    opportunity_master_docs = users.map { |user| [user, Rhosync::Store.get_data("source:application:#{user}:Opportunity:md")]}
  
    opportunity_master_docs.each do |user, opportunities|
      old_opportunities = opportunities.select do |key, opp| 
        begin
          opp['cssi_lastactivitydate'] && (Time.now - Time.parse(opp['cssi_lastactivitydate'])).to_days > 60 
        rescue 
          false
        end
      end
      Rhosync::Store.delete_data("source:application:#{user}:Opportunity:md", old_opportunities)
    end
  end 
end
