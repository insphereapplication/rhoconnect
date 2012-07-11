desc "Generate the apache httpd.conf file from the template"
task :gen_httpd_conf do
  require 'erb'
  document_root = "/var/www/InsiteMobile/current/public"
  passenger_module = "/opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.7/ext/apache2/mod_passenger.so"
  passenger_root = "/opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.7"
  passenger_pool_idle_time = 0
  max_rhoconnect_processes = 10
  min_rhoconnect_processes = 10
  server_name = "test.test.com"
  passenger_log_level = 3
  ruby_bin = "/opt/ruby-enterprise-1.8.7-2011.03/bin/ruby"
  current_release = "/var/www/InsiteMobile/current"
  web_port = "80"
  time = Time.now.strftime('%m/%d/%Y %r')
  
  template = ERB.new(File.read('config/templates/httpd.conf.erb'), nil, '<>')
  user = "dave.sims"
  result = template.result(binding)
  puts result
end

task :test_settings do 
  settings_path = File.expand_path(File.dirname(__FILE__)) + "/../settings/settings.yml"
  settings = File.readlines(settings_path)
  settings.map!{|l| l =~ /^:env:/ ? ":env: TEST\n"  : l }
  puts settings
end