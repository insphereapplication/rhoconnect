# env determines the environment section in settings/settings.yml that will be used by Rhoconnect
set :env, :onsite_model
# target servers 
role :app, "nrhrho204.uicnrh.dom", "nrhrho205.uicnrh.dom"
role :resque, "nrhrho204.uicnrh.dom"
set :server_name, "https://rhoconect.model.insphereis.net"
set :branch,      "master"