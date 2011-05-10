set :application, "InsiteMobile"
set :domain,      "mobile.insphere.com"
set :repository,  "git@git.rhohub.com:insphere/InsiteMobile-dev-rhosync.git"
set :branch,      "onsite_master"
set :use_sudo,    false
set :deploy_to,   "/var/www/#{application}"
set :deploy_via, :copy
set :scm,         :git
set :user,        "cap"
set :normalize_asset_timestamps, false

role :app, "nrhrho101"

namespace :deploy do
  task :start, :roles => :app do
    run "/usr/sbin/apachectl restart"
  end

  task :stop, :roles => :app do
    run  "/usr/sbin/apachectl stop"
  end

  desc "Restart Application"
  task :restart, :roles => :app do
     run "/usr/sbin/apachectl restart"
  end
end