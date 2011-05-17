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

role :app, "nrhrho101", "nrhrho102"

after "deploy:update", "deploy:set_license"
after "deploy:update", "deploy:gen_httpd_conf"
after "deploy:update", "deploy:fix_bootstrap"

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
    # run "apachectl -k graceful"
    # run "/etc/rc.d/init.d/httpd restart"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with Passenger"
    task t, :roles => :app do ; end
  end

  desc "Restart Application"
  task :restart, :roles => :app do
     run "touch #{current_release}/tmp/restart.txt"
    # run "apachectl -k graceful"
    # run "/etc/rc.d/init.d/httpd restart"     
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
    document_root = "/var/www/InsiteMobile/current/public"
    passenger_module = "/opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.7/ext/apache2/mod_passenger.so"
    passenger_root = "/opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.7"
    passenger_pool_idle_time = 0
    max_rhosync_processes = 10
    min_rhosync_processes = 10
    ruby_bin = "/opt/ruby-enterprise-1.8.7-2011.03/bin/ruby"
    current_release = "/var/www/InsiteMobile/current"
    server_name = "https://rhosync.insphereis.net"
    passenger_log_level = 3
    web_port = "80"
    time = Time.now.strftime('%m/%d/%Y %r')

    template = ERB.new(File.read('config/templates/httpd.conf.erb'), nil, '<>')
    result = template.result(binding)
    put(result, "#{current_release}/config/httpd.conf")
  end
  
  desc "A temp fix for the multi-process bug in Passenger" 
  task :fix_bootstrap, :roles => :app do 
    run "cd #{current_release}; rake server:fix_bootstrap"
  end
end

