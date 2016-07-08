class HMRhoconnectController < Rhoconnect::Controller::Base
  register Rhoconnect::EndPoint


  # add your custom routes here
    post '/reset_sync_status', :source_required => false do
		ExceptionUtil.rescue_and_reraise do
			SyncStatusUtil.reset_sync_status(@params[:user_pattern]).to_json
		end
	end
	
	post '/force_query', :source_required => false do
		ExceptionUtil.rescue_and_reraise do
			user_id = params[:user_id]
			source_id = params[:source_id]
    
			InsiteLogger.info "Forcing query for source #{source_id} for user #{user_id}"
		
			#First, reset the user's sync status to ensure do_query will actually do something below
			SyncStatusUtil.reset_sync_status(user_id)
    
			#Get an instance of the source adapter
			credential = {:app_id=>APP_NAME,:user_id=>user_id}
			source = Source.load(source_id,credential)
			source_adapter = SourceAdapter.create(source,credential)
    
			#Follow the sync contract by first logging into the backend then calling do_query to refresh RhoSync's dataset
			source_adapter.login
			source_adapter.do_query
    
			InsiteLogger.info "Done forcing query for source #{source_id} for user #{user_id}"
		end
	end
	
	post '/get_dead_locks', :source_required => false do
		ExceptionUtil.rescue_and_reraise do 
			dead_locks = LockUtil.get_dead_locks
			InsiteLogger.info(:format_and_join => ["Get dead locks checked for locks older than #{LockUtil.lock_age_threshold} seconds and returned ",dead_locks])
			dead_locks.to_json
		end
	end
	
	post '/get_log', :source_required => false do
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
	
	post '/get_sync_status', :source_required => false do
		ExceptionUtil.rescue_and_reraise do
			user_pattern = params[:user_pattern]
			init_key_pattern = "username:#{user_pattern}:[^:]*:initialized"
			refresh_time_key_pattern = "read_state:application:#{user_pattern}:[^:]*:refresh_time"
			init_keys = Store.get_store(0).db.keys(init_key_pattern)
			refresh_time_keys = Store.get_store(0).db.keys(refresh_time_key_pattern)
			
			refresh_time_values = {}
    
			refresh_time_keys.each do |key|
				refresh_time_values[key] = Store.get_store(0).db.get(key)
			end
    
			{:matching_init_keys => init_keys, :matching_refresh_time_keys => refresh_time_values}.to_json
		end	
	end
	
	post '/get_user_crm_id', :source_required => false do
		ExceptionUtil.rescue_and_reraise do
			username = params[:username]
			crm_id = UserUtil.get_crm_id(username)
			InsiteLogger.info("Got CRM user ID from rhoconnect for #{username}: #{crm_id}")
			crm_id
		end
	end
	
	post '/get_user_status', :source_required => false do
		ExceptionUtil.rescue_and_reraise do
			user_id = params[:user_id]
			disabled_at = UserUtil.disabled_at(user_id)
			status = disabled_at ? 'disabled' : 'enabled'
			{:status => status, :time => disabled_at}.to_json
		end
	end
	
	post '/push_deletes_custom', :source_required => false do
		ExceptionUtil.rescue_and_reraise do
			deleted_objects = params[:objects]
			InsiteLogger.info(:format_and_join => ["PUSH DELETES #{params[:source_id]} FOR #{params[:user_id]}: ",deleted_objects])
			deleted_objects = RedisUtil.get_existing_keys("#{params[:source_id]}", "#{params[:user_id]}", deleted_objects)
			InsiteLogger.info(:format_and_join => ["PUSH DELETES #{params[:source_id]} AFTER KEY CHECK FOR #{params[:user_id]}: ",deleted_objects])
			if !deleted_objects.empty?
				source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
				source_sync = Rhoconnect::Model::Base.create(source)    
				source_sync.push_deletes({:objects=>deleted_objects,:timeout=>nil,:raise_on_expire=>nil,:rebuild_md=>false})
			end
			'done'
		end
	end
	
	post '/push_mapped_objects', :source_required => false do
		ExceptionUtil.rescue_and_reraise do
			InsiteLogger.info "#"*80
			InsiteLogger.info "PUSH OBJECTS #{params[:source_id]} OBJECTS FOR #{params[:user_id]}"
			
			source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})

			InsiteLogger.info "SOURCE:"
			InsiteLogger.info source
			InsiteLogger.info "SOURCE USER: #{source.user.inspect}"
			
			objects = Mapper.map_source_data(params[:objects], params[:source_id])
		  
			UpdateUtil.push_objects(source, objects, true)
			""
		end
	end
	
	post '/push_objects_notify', :source_required => false do
		ExceptionUtil.rescue_and_reraise do
			begin
			  InsiteLogger.info "#"*80
			  InsiteLogger.info "PUSH OBJECTS NOTIFY #{params[:source_id]} OBJECTS FOR #{params[:user_id]}"

			  source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
			  InsiteLogger.info "SOURCE: #{source.inspect}"
			  InsiteLogger.info "SOURCE USER: #{source.user.inspect}"

			  objects = Mapper.map_source_data(params[:objects], params[:source_id])
			  UpdateUtil.push_objects(source, objects, true)
			ensure
        # Ensure that the user gets a push notification even if push_objects fails
        InsiteLogger.info "push_objects_notify called, notifying observer for #{params[:source_id]}"
        klass = Object.const_get(params[:source_id].capitalize)
        klass.push_notification(params[:user_id], objects) if klass.respond_to?(:push_notification)
			end
			""
		end
	end
	
	post '/release_lock', :source_required => false do
		ExceptionUtil.rescue_and_reraise do
			lock = params[:lock]
			InsiteLogger.info("Releasing lock '#{lock}'")
			
			if LockUtil.release_lock(lock)
				result = "Successfully released lock '#{lock}'"
				InsiteLogger.info(result)
				result
			else
				raise "Lock '#{lock}' doesn't exist"
			end
		end
	end
	
	post '/set_user_status', :source_required => false do
		ExceptionUtil.rescue_and_reraise do
			user_id = params[:user_id]
			status = params[:status]
			InsiteLogger.info("Setting user status to #{status} for user #{user_id}")
			case status
			when 'enabled'
			  UserUtil.enable_if_disabled(user_id)
			when 'disabled'
			  UserUtil.disable_if_enabled(user_id)
			else
			  raise "Status must either be 'enabled' or 'disabled'"
			end
			'done'
		end
	end
	
end
