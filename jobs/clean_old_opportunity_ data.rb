require 'rhosync'

class CleanOldOpportunityData
  
  @queue = :clean_old_opportunity_data
  @redis = Redis.new
  
  def self.perform
    users = @redis.keys('user:*:rho__id').map{|u| @redis.get(u)}
    opportunity_master_docs = users.map { |user| [user, Rhosync::Store.get_data("source:application:#{user}:Opportunity:md")]}
    opportunity_master_docs.each do |user, opportunities|
      old_opportunities = opportunities.select do |key, opp| 
        begin
          opp['createdon'] && (Time.now - Time.parse(opp['createdon'])).to_days > 60 
        rescue 
          false
        end
      end
      Rhosync::Store.delete_data("source:application:#{user}:Opportunity:md", old_opportunities)
    end
  end
end
