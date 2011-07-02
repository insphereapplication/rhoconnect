# env determines the environment section in settings/settings.yml that will be used by Rhosync
set :env, :onsite_model
# target servers 
role :app, "nrhrho201.uicnrh.dom", "nrhrho202.uicnrh.dom"
role :resque, "nrhrho201.uicnrh.dom"
set :server_name, "https://rhosync.model.insphereis.net"
set :branch,      "master"

before "deploy:update", "resque:stop_workers"
before "deploy:update", "resque:stop_console"

after "deploy:update", "resque:start_workers"
after "deploy:update", "resque:start_console"