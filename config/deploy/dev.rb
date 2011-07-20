# env determines the environment section in settings/settings.yml that will be used by Rhosync
set :env, :onsite_dev
# target servers 
role :app, "nrhrhod401.uicnrh.dom"
role :resque, "nrhrhod401.uicnrh.dom"
set :server_name, "https://rhosync.dev.insphereis.net"
set :branch,      "master"