class DeviceInfo < SourceAdapter
  def initialize(source)
    super(source)
  end
 
  def login
    # TODO: Login to your data source here if necessary
  end
 
  def query(params=nil)
   
  end
 
  def sync

  end
 
  def create(device_info,blob=nil)
    ExceptionUtil.rescue_and_reraise do
      device_info.merge!({
        "server_last_update" => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
      })
      
      InsiteLogger.info(:format_and_join => ["!!! Device Info created: ",device_info])
      
      device_info['client_id']
    end
  end
 
  def update(update_device_info)
     ExceptionUtil.rescue_and_reraise do
        InsiteLogger.info "Device Info"
        ExceptionUtil.context(:current_user => current_user.login, :update_hash => update_device_info )
        update_device_info.merge!({
          "server_last_update" => Time.now.strftime("%Y-%m-%d %H:%M:%S %z")
        })
        InsiteLogger.info(:format_and_join => ["!!! Device Info updated: ",update_device_info])
        
        UpdateUtil.push_update(@source, update_device_info)

      end
    
  end
 
  def delete(delete_hash)
    
  end
 
  def logoff
   
  end
end