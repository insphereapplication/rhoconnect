app_path = File.expand_path(File.join(File.dirname(__FILE__)))
require "#{app_path}/../util/email_util"

require "#{app_path}/health_checks/health_check"
Dir[File.join(File.dirname(__FILE__),'health_checks','**','*.rb')].each { |file| require file } #require all validation checks

class ValidateRedisData
  @queue = :validate_redis_data

  include RhosyncResqueJob
  
  class << self
    def send_email(email_body)
      ExceptionUtil.rescue_and_reraise do
        to = CONFIG[:resque_data_validation_email_group]
        subject = "RhoSync Data Validation Results - " + Time.now.strftime("%m%d%Y")
        EmailUtil.send_mail(to, subject, email_body)
      end
    end

    def perform
      log "*"*20 + "Starting Validate_Redis_Data job"
      log "Target rhosync host: #{CONFIG[:resque_worker_rhosync_api_host]}"
      
      checks = [
        DeadLockCheck.new,
        OpportunityTrueUpCheck.new,
        OpportunityIntegrityCheck.new,
        PolicyIntegrityCheck.new,
        UnhandledExceptionCheck.new,
        DevicePinCheck.new
      ]
      
      environment = CONFIG[:env]
      start_time = Time.now
          
      log "*"*15 + "Sending email with summary data"
          
      # send an email with the results
      file_path = File.expand_path(File.join(File.dirname(__FILE__))) + '/templates/validation_email.erb'
      email_template = ERB.new( File.read(file_path), nil, '<>')
      result = email_template.result(binding)
      send_email(result)
      
      log "*"*20 + "Done with Validate_Redis_Data!"
    end
  end
end
