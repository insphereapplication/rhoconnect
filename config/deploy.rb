set :stages, %w(model prod dev resque_model resque_prod)
set :default_stage, 'model'
require 'capistrano/ext/multistage'
require 'ap'

set :application, "InsiteMobile"
set :domain,      "rhosync.insphereis.net"
set :repository,  "git@git.rhohub.com:insphere/InsiteMobile-dev-rhosync.git"
set :use_sudo,    false
set :deploy_to,   "/var/www/#{application}"
set :deploy_via, :copy
set :scm,         :git
set :user,        "cap"
set :normalize_asset_timestamps, false

# apache config properties -- see: templates/httpd.conf.erb
set :admin_email, "admin@insphereis.net"
#set :apache_user, "apache"
#set :apache_group, "apache"
set :document_root, "#{deploy_to}/current/public"
set :web_port, "80"
set :time, Time.now.strftime('%m/%d/%Y %r')


set :ruby_bin, "/opt/rhoconnect/bin/ruby"

after "deploy:update", "deploy:settings"
after "deploy:update", "deploy:set_license"
#after "deploy:update", "deploy:httpd_conf"
after "deploy:update", "deploy:gemfile"

before "deploy:update", "resque:stop"
after "deploy:update", "resque:start"

# Runs the given command as the given user. Prompts for the user's password then passes that as a response to any password prompts
def run_as_user_send_password(user, command)
  @response_hash = {}
  password = fetch(:root_password, Capistrano::CLI.password_prompt("password for #{user}: "))
  run("su - #{user} -c '#{command}'", {:pty => true}) do |channel, stream, output|
    if output[/Password: /] or output[/\[sudo\] password/]
      puts "Got output #{output}, sending password"
      channel.send_data("#{password}\n") 
      @response_hash[channel[:host]] = ''
    else
      @response_hash[channel[:host]] ||= ''
      @response_hash[channel[:host]] += output
    end
  end
  @response_hash.each{|host,response| 
    puts "Response from #{host}:"
    puts response
  }
end

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with Passenger"
    task t, :roles => :app do ; end
  end

  desc "Restart Application"
  task :restart, :roles => :app do
     run_as_user_send_password(user, "sudo /etc/init.d/thin restart -e production --servers 10 --onebyone --wait 2")
  end
  
  desc "Copy the onsite Gemfile/Gemfile.lock files up to the server"
  task :gemfile, :roles => :app do 
    # Modifiying theis step on 07-12-2012 as the code Gemfiles should be deployed from source and not local machine
    run "mv #{current_release}/config/gemfiles/onsite/Gemfile #{current_release}/Gemfile"
    run "mv #{current_release}/config/gemfiles/onsite/Gemfile.lock #{current_release}/Gemfile.lock"

  end
  
  # The set_license task assumes that there is a license key file named "<hostname*>" in the settings/host_keys directory
  # in source control for every deployment target defined above in "role :app, '<hostname1>', '<hostname2>'", etc.
  # It will copy the server-specific license key to the /settings/license.key file which Rhoconnect will use
  # for that server.
  desc "Set the Rhoconnect license key for the particular host machine"
  task :set_license , :roles => :app do
    run "mv #{current_release}/settings/host_keys/$CAPISTRANO:HOST$ #{current_release}/settings/license.key"
  end


  
  desc "Sets the environment of settings/settings.yml to use the environment defined in 'env'"
  task :settings, :roles => :app do 
    settings = "#{current_release}/settings/settings.yml"
    temp = "#{current_release}/settings.tmp"
    run("sed -e 's/^\:env:.*/:env: #{env}/g' #{settings} > #{temp}; mv #{temp} #{settings}")
  end
  
  desc "Deploys the logrotate config to each app server. Requires sudo, so call like this: \"cap deploy:logrotate_config -s runas=<username>\""
  task :logrotate_config, :roles => :app do
    require 'erb'
    abort "Please provide a user w/ sudo to run this command as (i.e. cap deploy:logrotate_config -s runas=<username>)" unless exists?(:runas)
    template = ERB.new(File.read('config/templates/passenger.logrotate.erb'), nil, '<>')
    result = template.result(binding)
    temp_logrotate_path = "#{shared_path}/passenger.logrotate.temp"
    put(result, temp_logrotate_path)
    run_as_user_send_password(runas, "sudo cp #{temp_logrotate_path} /etc/logrotate.d/passenger")
    run("rm #{temp_logrotate_path}")
  end
end

# Enhanced utilization of capistrano's run() method, but keeps the output from each server distinct by maintaining a hash mapping the server's hostname to its response
def run_and_gather_responses(command)
  host_responses = {}
  
  # run the given command & gather responses from servers in a hash mapping server hostname => response
  run(command) do |channel, stream, output|
    host_responses[channel[:host]] ||= ''
    host_responses[channel[:host]] += output
  end
  
  host_responses
end

namespace :resque do 
  
  QUEUE_NAMES = ["limit_client_exceptions","clean_old_opportunity_data","validate_redis_data", "deactivate_inactive_user", "release_dead_locks"]
  
  desc "Restart the resque jobs"  
  task :restart, :roles => :resque do 
    stop
    start
  end
  
  desc "Stop the resque jobs"  
  task :stop, :roles => :resque do
    stop_scheduler
    stop_workers
    stop_console
  end
  
  desc "Start the resque jobs"  
  task :start, :roles => :resque do
    start_console
    start_workers
    start_scheduler
  end
  
  task :stop_workers, :roles => :resque do
    QUEUE_NAMES.each{|queue| run "ps -ef | grep -P '^((?!grep).)*resque.*#{queue}.*$' | awk '{print $2}' | xargs -rt kill; true"}
  end
  
  task :start_workers, :roles => :resque do 
    QUEUE_NAMES.each{|queue| run "cd #{current_release}/jobs; /opt/rhoconnect/bin/rake resque:work_with_logging['#{queue}'] &> /dev/null &"}
  end
  
  task :start_console, :roles => :resque do 
   run "cd #{current_release}/jobs; /opt/rhoconnect/bin/resque-web resque_config.rb -p 8282"
  end
  
  task :stop_console, :roles => :resque do
    run "ps -ef | grep -P '^((?!grep).)*resque-web.*$' | awk '{print $2}' | xargs -rt kill; true"
  end
  
  task :start_scheduler, :roles => :resque do
    run "cd #{current_release}/jobs;  /opt/rhoconnect/bin/rake resque:scheduler >> #{shared_path}/log/jobs/resque_scheduler.log &"
  end
  
  task :stop_scheduler, :roles => :resque do
    run "ps -ef | grep -P '^((?!grep).)*resque:scheduler.*$' | awk '{print $2}' | xargs -rt kill; true"
  end
end

namespace :util do  
  desc "Stream the rhoconnect log from all target servers in a single terminal" 
  task :stream_logs, :roles => :app do
    stream "tail -F #{shared_path}/log/insite_mobile.log"
  end
  
  desc %Q{
    Grep the current app logs for a given pattern.
    Call as follows: cap util:grep_logs -s pattern="<grep_pattern>"

    This can also be used to grep other files on each app server: provide the grep_path option (i.e. to grep apache error logs run: 'cap util:grep_logs -s pattern=<pattern> -s grep_path="/var/log/httpd/error_log"')
  }
  task :grep_logs, :roles => :app do
    abort "Please provide the \"pattern\" option when calling grep_logs (i.e. cap util:grep_logs -s pattern=<grep_pattern>)" unless exists?(:pattern)
    path_to_grep = exists?(:grep_path) ? grep_path : "#{shared_path}/log/insite_mobile.log"
    options = exists?(:grep_options) ? " #{grep_options}" : ""
    results = run_and_gather_responses("grep#{options} -E '#{pattern}' \"#{path_to_grep}\"; true") #'true' is needed at the end so that capsitrano won't report an empty grep result as a failure
    results.each{|host,response| 
      marker = "="*20
      puts "\n\n#{marker} Response from #{host}: #{marker}\n\n"
      puts response
    }
  end
  
  task :download_logs, :roles => :app do
    time_now_formatted = Time.now.strftime("%Y%m%d%H%M%S")
    log_file_path = "#{shared_path}/log"
    dump_file_name = "#{time_now_formatted}_log_dump.tgz"
    
    #tar logs on each server
    run("cd #{log_file_path}; tar -cvjf #{dump_file_name} *.log*")
    
    #download logs from each server
    base_log_dump_path = "log_dumps"
    Dir.mkdir(base_log_dump_path) unless File.exists?(base_log_dump_path + "/")
    timestamped_dump_path = "#{base_log_dump_path}/#{time_now_formatted}"
    Dir.mkdir(timestamped_dump_path) unless File.exists?(timestamped_dump_path + "/")
    download("#{log_file_path}/#{dump_file_name}", "#{timestamped_dump_path}/$CAPISTRANO:HOST$.tgz")
    
    #clean up temp tar from each server
    run("rm #{log_file_path}/#{dump_file_name}")
    
    #untar locally & gunzip archived logs to make them greppable
    Dir.foreach(timestamped_dump_path) do |item|
      next if item == '.' or item == '..'
      
      server_name = item.gsub(/\.tgz/,'')
      tar_path = "#{timestamped_dump_path}/#{item}"
      untar_dir = "#{timestamped_dump_path}/#{server_name}"
      Dir.mkdir(untar_dir)
      `mv #{tar_path} #{untar_dir}/`
      `cd #{untar_dir}; tar -xvjf #{item}; rm #{item}; gunzip *.gz`
    end
    
    puts "Downloaded log files to #{timestamped_dump_path}"
  end
  
  desc "Shows statistics on sockets established from each app server to redis (include flag '-s raw_netstat' to see the raw netstat output)"
  task :show_redis_sockets, :roles => :app do
    # run netstat & gather responses from servers in a hash mapping server hostname => response
    run_and_gather_responses('netstat -a | grep ":6379[^0-9]"; true').each{|host,result|
      # sum socket counts as we go along
      total_socket_count = 0
      
      # Determine the number of sockets in each of the following states and put into a hash mapping states to their respective count
      socket_state_counts = ["ESTABLISHED", "CLOSE_WAIT", "FIN_WAIT", "CLOSED"].reduce({}){|sum,socket_state|
        state_count = result.scan(Regexp.new(socket_state,true)).length
        total_socket_count += state_count
        sum[socket_state] = state_count
        sum
      }
      
      puts "#{'*'*10} Results from #{host}: #{'*'*10}"
      puts "Total redis socket count: #{total_socket_count}"
      puts "State counts:"
      ap(socket_state_counts,:plain => true)
      if exists?(:raw_netstat)
        puts "Raw results:"
        puts result
      end
    }
  end
end


