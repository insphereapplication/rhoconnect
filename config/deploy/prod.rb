# env determines the environment section in settings/settings.yml that will be used by Rhosync
set :env, :onsite
# target servers 
role :app, "nrhrho101.pinsp.dom", "nrhrho102.pinsp.dom"
role :resque, "nrhrho101.pinsp.dom"
set :server_name, "https://rhosync.insphereis.net"
set :branch,      "v2.0.10_prod"