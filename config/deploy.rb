set :stages, %w(model prod)
set :default_stage, 'model'
require 'capistrano/ext/multistage'
require 'ap'

set :application, "InsiteMobile"
set :domain,      "rhosync.insphereis.net"
set :repository,  "git@git.rhohub.com:insphere/InsiteMobile-dev-rhosync.git"
set :use_sudo,    false
set :deploy_to,   "/var/www/#{application}"
set :deploy_via, :copy
set :scm,         :git
set :user,        "cap"
set :normalize_asset_timestamps, false

# apache config properties -- see: templates/httpd.conf.erb
set :admin_email, "admin@insphereis.net"
set :apache_user, "apache"
set :apache_group, "apache"
set :document_root, "#{deploy_to}/current/public"
set :web_port, "80"
set :time, Time.now.strftime('%m/%d/%Y %r')

# passenger config properties -- see: templates/httpd.conf.erb
set :passenger_pool_idle_time, 0
set :passenger_max_pool_size, 30
set :passenger_min_instances, 10
set :passenger_log_level, 3
set :passenger_module, "/opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.7/ext/apache2/mod_passenger.so"
set :passenger_root, "/opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.7"
set :ruby_bin, "/opt/ruby-enterprise-1.8.7-2011.03/bin/ruby"

after "deploy:update", "deploy:settings"
after "deploy:update", "deploy:set_license"
after "deploy:update", "deploy:httpd_conf"
after "deploy:update", "deploy:gemfile"

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
  
  desc "Copy the onsite Gemfile/Gemfile.lock files up to the server"
  task :gemfile, :roles => :app do 
    gemfiles_path = File.expand_path(File.dirname(__FILE__)) + "/gemfiles/onsite/"
    gemfile = File.read(gemfiles_path + "Gemfile")
    gemfile_lock = File.read(gemfiles_path + "Gemfile.lock")
    put(gemfile, "#{current_release}/Gemfile")
    put(gemfile_lock, "#{current_release}/Gemfile.lock")
  end
  
  # The set_license task assumes that there is a license key file named "<hostname*>" in the settings/host_keys directory
  # in source control for every deployment target defined above in "role :app, '<hostname1>', '<hostname2>'", etc.
  # It will copy the server-specific license key to the /settings/license.key file which Rhosync will use
  # for that server.
  desc "Set the Rhosync license key for the particular host machine"
  task :set_license , :roles => :app do
    run "mv #{current_release}/settings/host_keys/$CAPISTRANO:HOST$ #{current_release}/settings/license.key"
  end

  # For this task to have an effect, all target servers need to replace /etc/httpd/conf/httpd.conf with a symlink pointing 
  # to <current_release>/config/httpd.conf
  #
  # Apache needs to be restarted for changes in httpd.conf to be reflected. Running cap deploy:update only restarts Passenger.
  #
  # To restart Apache, on all target machines: sudo apachectl -k graceful.
  #
  desc "Generate the apache httpd.conf file from the config/templates/httpd.conf.template"
  task :httpd_conf do
    require 'erb'
    template = ERB.new(File.read('config/templates/httpd.conf.erb'), nil, '<>')
    result = template.result(binding)
    put(result, "#{current_release}/config/httpd.conf")
  end
  
  desc "Sets the environment of settings/settings.yml to use the environment defined in 'env'"
  task :settings do 
    settings = "#{current_release}/settings/settings.yml"
    temp = "#{current_release}/settings.tmp"
    run("sed -e 's/^\:env:.*/:env: #{env}/g' #{settings} > #{temp}; mv #{temp} #{settings}")
  end
  
  def run_as_user_send_password(user, command)
    @response_hash = {}
    password = fetch(:root_password, Capistrano::CLI.password_prompt("password for #{user}: "))
    run("su - #{user} -c '#{command}'", {:pty => true}) do |channel, stream, output|
      if output[/Password: /] or output[/\[sudo\] password/]
        puts "Got output #{output}, sending password"
        channel.send_data("#{password}\n") 
        @response_hash[channel[:host]] = ''
      else
        @response_hash[channel[:host]] ||= ''
        @response_hash[channel[:host]] += output
      end
    end
    @response_hash.each{|host,response| 
      puts "Response from #{host}:"
      puts response
    }
  end
  
  task :logrotate_config, :roles => :app do
    require 'erb'
    abort "Please provide a user w/ sudo to run this command as (i.e. cap deploy:logrotate_config -s runas=<username>)" unless exists?(:runas)
    template = ERB.new(File.read('config/templates/passenger.logrotate.erb'), nil, '<>')
    result = template.result(binding)
    temp_logrotate_path = "#{shared_path}/passenger.logrotate.temp"
    put(result, temp_logrotate_path)
    run_as_user_send_password(runas, "sudo cp #{temp_logrotate_path} /etc/logrotate.d/passenger")
    run("rm #{temp_logrotate_path}")
  end
end

namespace :util do  
  desc "Stream the rhosync log from all target servers in a single terminal" 
  task :stream_logs, :roles => :app do
    stream "tail -F #{shared_path}/log/insite_mobile.log"
  end
  
  desc "Grep the current logs for a given pattern.\nCall as follows: cap util:grep_logs -s pattern=\"<grep_pattern>\""
  task :grep_logs do
    abort "Please provide the \"pattern\" option when calling grep_logs (i.e. cap util:grep_logs -s pattern=<grep_pattern>)" unless exists?(:pattern)
    run("grep \"#{pattern}\" #{shared_path}/log/insite_mobile.log; true") #'true' is needed at the end so that capsitrano won't report an empty grep result as a failure
  end
end


