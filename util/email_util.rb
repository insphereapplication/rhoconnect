app_path = File.expand_path(File.join(File.dirname(__FILE__))) 
require "#{app_path}/../util/config_file"
require 'pony'

module EmailUtil
  
  def self.send_mail(to, subject, msg)    
    cmd = "echo '#{msg}' |mailx -s \"#{subject}\" #{to}"
    puts "*"*10 + "Sending mail using EmailUtil"
    puts `#{cmd}`
  end  
end