# env determines the environment section in settings/settings.yml that will be used by Rhoconnect
set :env, :onsite
# target servers 
role :app, "nrhrho101.pinsp.dom", "nrhrho102.pinsp.dom"
role :resque, "nrhrho101.pinsp.dom"
set :server_name, "https://rhosync.insphereis.net"
set :branch,      "v3.4.0_prod"

