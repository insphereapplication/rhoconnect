require 'resque_scheduler'
Resque.redis = 'nrhrho203:6379'
Resque.schedule = YAML.load_file('settings/resque_schedule.yml')