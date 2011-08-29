class DevicePinCheck < HealthCheck
  include AgentFailureFilters
  
  def initialize
    super("Device pin")
    @results = {}
    run
  end
  
  def run
    log_run
    HealthCheckUtil.users.each do |user|
      log_and_continue do        
        log "*"*10 + "Checking user device pins #{user}"
        user_devices = HealthCheckUtil.rhosync_api.get_user_devices(user)
        next if user_devices.empty?

        log "Devices in Rhosync: #{user_devices.count}"

        devices_missing_pin = []
        user_devices.each do |device_id|
          device_pin = HealthCheckUtil.rhosync_api.get_device_params(device_id).select{ |k| k['name'] == 'device_pin' }.first        
          devices_missing_pin << device_id if device_pin.nil? || (!device_pin.nil? && device_pin['value'].nil?)      
        end
        log "#{user} has #{devices_missing_pin.count} device(s) missing pin of #{user_devices.count}: #{devices_missing_pin.inspect}"
        @results[user] = {:passed => (devices_missing_pin.count == 0), :user_devices => user_devices, :user_devices_missing_pin => devices_missing_pin}
      end
    end
  end
  
  def result_summary
    total_user_count = HealthCheckUtil.users.count
    super + " #{agent_failures.count} agents and #{other_failures.count} others failed out of #{total_user_count} total users."
  end
  
  def result_details
    details = failures.sort{|x,y| x[0] <=> y[0]}.reduce([]){|sum,(user,result)|
      sum << "#{user} - #{result[:user_devices_missing_pin].count} of #{result[:user_devices].count} device(s) have missing pins."
      sum
    }.join("\n")
    super + "\n#{details}"
  end
end