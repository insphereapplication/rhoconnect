set :application, "InsiteMobile"
set :domain,      "10.143.28.181"
set :repository,  "git@git.rhohub.com:insphere/InsiteMobile-dev-rhosync.git"
set :use_sudo,    false
set :deploy_to,   "/var/www/#{application}"
set :deploy_via, :copy
set :scm,         :git
set :user,        "dsims"

server "10.143.28.181", :app, :web

namespace :deploy do
  task :start, :roles => :app do
    run "apachectl restart"
  end

  task :stop, :roles => :app do
    run  "apachectl stop"
  end

  desc "Restart Application"
  task :restart, :roles => :app do
     run "apachectl restart"
  end
end