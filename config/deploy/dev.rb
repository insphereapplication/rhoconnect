# env determines the environment section in settings/settings.yml that will be used by Rhoconnect
set :env, :onsite_dev
# target servers 
role :app, "nrhrhod404.uicnrh.dom"
role :resque, "nrhrhod404.uicnrh.dom"
set :server_name, "https://rhoconnect.dev.insphereis.net"
set :branch,      "5.4"