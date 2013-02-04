# env determines the environment section in settings/settings.yml that will be used by Rhoconnect
set :env, :onsite
# target servers 
role :app, "nrhrhop104.uicnrh.dom", "nrhrhop105.uicnrh.dom"
role :resque, "nrhrhop104.uicnrh.dom"
set :server_name, "https://rhoconnect.insphereis.net"
set :branch,      "v4.0.5_prod"


