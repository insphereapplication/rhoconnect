# env determines the environment section in settings/settings.yml that will be used by Rhosync
set :env, :onsite_model
# target servers 
role :app, "nrhrho201.uicnrh.dom", "nrhrho202.uicnrh.dom"
role :resque, "nrhrho201.uicnrh.dom"
set :server_name, "https://rhosync.model.insphereis.net"
set :branch,      "master"
