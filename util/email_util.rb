module EmailUtil
  def self.send_mail(to, subject, msg)    
    cmd = "echo '#{msg}' |mailx -s \"#{subject}\" #{to}"
    puts "*"*10 + "Sending mail using EmailUtil"
    puts `#{cmd}`
  end
end