# env determines the environment section in settings/settings.yml that will be used by Rhosync
set :env, :onsite
# target servers 
role :app, "nrhrho101", "nrhrho102"
set :server_name, "https://rhosync.insphereis.net"
set :branch,      "insite_mobile_1_1"