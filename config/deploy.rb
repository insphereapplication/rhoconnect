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

after "deploy:update", :set_license

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # run  "/usr/sbin/apachectl stop"
  end

  desc "Restart Application"
  task :restart, :roles => :app do
     run "touch #{current_release}/tmp/restart.txt"
  end
end

desc "Set the Rhosync license key for the particular host machine"
task :set_license , :roles => :app do
  # This task assumes that there is a license key file named "<hostname>_license.key" in the settings directory
  # in source control for every deployment target defined above in "role :app, '<hostname>', '<hostname>'", etc.
  # It will copy the server-specific license key to the /settings/license.key file which Rhosync will use
  # for that server.
  run "mv #{current_release}/settings/$CAPISTRANO:HOST$_license.key #{current_release}/settings/license.key"
end