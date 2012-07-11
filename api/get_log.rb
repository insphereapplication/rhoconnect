Rhoconnect::Server.api :get_log do |params,user|
  ExceptionUtil.rescue_and_reraise do
    log_file_path = CONFIG[:log][:path]
    log = ''
    
    if File.exists?(log_file_path)
      log = File.open(log_file_path, 'rb') { |f| f.read }
    else
      log = 'Log file doesn\'t exist'
    end
    
    log
  end
end