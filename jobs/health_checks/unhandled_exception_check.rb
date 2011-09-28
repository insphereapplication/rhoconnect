class UnhandledExceptionCheck < HealthCheck
  include AgentFailureFilters
  
  def initialize
    super("Unhandled E400/E500 exception")
    @results = {}
    run
  end
  
  def run
    log_run
    HealthCheckUtil.users.each do |user|
      ExceptionUtil.rescue_and_continue do
        InsiteLogger.info "*"*10 + "Checking for unhandled client expections #{user}"
        client_exception_data = HealthCheckUtil.get_rhosync_source_data( user, 'ClientException')
        client_exception_counter = 0
        client_exception_data.each do |id, client_exception|
          client_exception_type = client_exception['exception_type']
          begin
          parsed_created_on = Time.parse(client_exception['server_created_on'])
          client_exception_counter += 1 if (['E400','E500'].include?(client_exception_type) && (parsed_created_on + (60 * 60 * 24) > Time.now))
          rescue
            #ignore client exceptions that don't have a server created on specified
          end
        end
      
        InsiteLogger.info "#{user} has #{client_exception_counter} unhandled E400/E500 errors in the last 24 hours."

        @results[user] = {:passed => (client_exception_counter == 0), :unhandled_exception_counter => client_exception_counter}
      end
    end
  end
  
  def result_summary
    total_user_count = HealthCheckUtil.users.count
    super + " #{agent_failures.count} agents and #{other_failures.count} others failed out of #{total_user_count} total users."
  end
  
  def result_details
    details = failures.sort{|x,y| x[0] <=> y[0]}.reduce([]){|sum,(user,result)|
      sum << "#{user} had #{result[:unhandled_exception_counter]} unhandled client E400/E500 exceptions."
      sum
    }.join("\n")
    super + "\n#{details}"
  end
end