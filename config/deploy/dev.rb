# env determines the environment section in settings/settings.yml that will be used by Rhoconnect
set :env, :onsite_dev
# target servers 
role :app, "nrhrhod404.uicnrh.dom"
role :resque, "nrhrhod404.uicnrh.dom"
set :server_name, "http://nrhrhod406"
set :branch,      "rhoconnect"