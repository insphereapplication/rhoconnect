set :application, "InsiteMobile"
set :domain,      "rhosync.insphereis.net"
set :repository,  "git@git.rhohub.com:insphere/InsiteMobile-dev-rhosync.git"
set :branch,      "onsite_master"
set :use_sudo,    false
set :deploy_to,   "/var/www/#{application}"
set :deploy_via, :copy
set :scm,         :git
set :user,        "cap"
set :normalize_asset_timestamps, false
set :env, 'onsite'

# apache/passenger config properties -- these are used by templates/httpd.conf.erb
set :document_root, "/var/www/InsiteMobile/current/public"
set :passenger_module, "/opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.7/ext/apache2/mod_passenger.so"
set :passenger_root, "/opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.7"
set :passenger_pool_idle_time, 0
set :max_rhosync_processes, 3
set :min_rhosync_processes, 3
set :ruby_bin, "/opt/ruby-enterprise-1.8.7-2011.03/bin/ruby"
set :server_name, "https://rhosync.insphereis.net"
set :passenger_log_level, 3
set :web_port, "80"
set :time, Time.now.strftime('%m/%d/%Y %r')

role :app, "nrhrho101", "nrhrho102"

after "deploy:update", "deploy:set_environment"
after "deploy:update", "deploy:set_license"
after "deploy:update", "deploy:gen_httpd_conf"

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with Passenger"
    task t, :roles => :app do ; end
  end

  desc "Restart Application"
  task :restart, :roles => :app do
     run "touch #{current_release}/tmp/restart.txt"
  end
  
  # The set_license task assumes that there is a license key file named "<hostname>" in the settings/host_keys directory
  # in source control for every deployment target defined above in "role :app, '<hostname>', '<hostname>'", etc.
  # It will copy the server-specific license key to the /settings/license.key file which Rhosync will use
  # for that server.
  desc "Set the Rhosync license key for the particular host machine"
  task :set_license , :roles => :app do
    run "mv #{current_release}/settings/host_keys/$CAPISTRANO:HOST$ #{current_release}/settings/license.key"
  end

  # For this task to have an effect, all target servers need to replace /etc/httpd/conf/httpd.conf with a symlink pointing to <current_release>/config/httpd.conf
  desc "Generate the apache httpd.conf file from the config/templates/httpd.conf.template"
  task :gen_httpd_conf do
    require 'erb'

    template = ERB.new(File.read('config/templates/httpd.conf.erb'), nil, '<>')
    result = template.result(binding)
    put(result, "#{current_release}/config/httpd.conf")
  end
  
  desc "Sets the environment of settings/settings.yml to use the environment defined in 'env'"
  task :set_environment do 
    settings_path = File.expand_path(File.dirname(__FILE__)) + "/../settings/settings.yml"
    settings = File.readlines(settings_path)
    settings.map!{|l| l =~ /^:env:/ ? ":env: #{env}\n"  : l }
    puts (settings, "#{current_release}/settings/settings.yml"
  end
end

