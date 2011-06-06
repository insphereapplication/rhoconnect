# env determines the environment section in settings/settings.yml that will be used by Rhosync
set :env, :onsite_model
# target servers 
role :app, "nrhrho201", "nrhrho202"
set :server_name, "https://rhosync.model.insphereis.net"
set :branch,      "2-0_iter1"