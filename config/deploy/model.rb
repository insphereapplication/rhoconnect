# env determines the environment section in settings/settings.yml that will be used by Rhoconnect
set :env, :onsite_model
# target servers 
role :app, "nrhrhom204.uicnrh.dom", "nrhrhom205.uicnrh.dom"
role :resque, "nrhrhom204.uicnrh.dom"
set :server_name, "https://rhoconnect.model.insphereis.net"
set :branch,      "5.4"