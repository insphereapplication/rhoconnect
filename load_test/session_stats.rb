class SessionStats
  attr_accessor :start_time, :end_time
  
  def initialize
    @stats = []
  end
  
  def requests_per_sec
    total_time/@stats.size
  end
  
  def reset
    @stats = []
  end
  
  def get_stats
    @stats
  end  
  
  def add_stats(stats)
     stats.each {|stat| @stats << stat}
  end
  
  def total_time
    @total_time ||= (end_time - start_time)
  end
  
  def max_time
    @stats.map{|stat| stat[:time]}.max
  end
  
  def min_time
    @stats.map{|stat| stat[:time]}.min
  end
  
  def total_creates
    @stats.select{|stat| stat[:action] == "post" && stat[:args][:create]}.size
  end
  
  def total_gets
    temp = @stats.select{|stat| stat[:action] == "get"}.size
  end
  
  def total_source_creates(source_name)
     @stats.select{|stat| stat[:action] == "post" && stat[:args][:create] && stat[:args][:source_name] == source_name}.size
  end

  def total_source_creates_min(source_name)
   temp = @stats.select{|stat| stat[:action] == "post" && stat[:args][:create] && stat[:args][:source_name] == source_name}
   temp.map{|stat| stat[:time]}.min
  end

  def total_source_creates_max(source_name)
   temp = @stats.select{|stat| stat[:action] == "post" && stat[:args][:create] && stat[:args][:source_name] == source_name}
   temp.map{|stat| stat[:time]}.max
  end

  def total_source_creates_avg(source_name)
   temp = @stats.select{|stat| stat[:action] == "post" && stat[:args][:create] && stat[:args][:source_name] == source_name}
   temp2 = temp.map{|time| time[:time]}
   temp2.inject(0, &:+) / temp.size if temp.size > 0
  end
  
  def total_source_updates(source_name)
     @stats.select{|stat| stat[:action] == "post" && stat[:args][:update] && stat[:args][:source_name] == source_name}.size
  end

  def total_source_updates_min(source_name)
   temp = @stats.select{|stat| stat[:action] == "post" && stat[:args][:update] && stat[:args][:source_name] == source_name}
   temp.map{|stat| stat[:time]}.min
  end

  def total_source_updates_max(source_name)
   temp = @stats.select{|stat| stat[:action] == "post" && stat[:args][:update] && stat[:args][:source_name] == source_name}
   temp.map{|stat| stat[:time]}.max
  end

  def total_source_updates_avg(source_name)
   temp = @stats.select{|stat| stat[:action] == "post" && stat[:args][:update] && stat[:args][:source_name] == source_name}
   temp2 = temp.map{|time| time[:time]}
   temp2.inject(0, &:+) / temp.size if temp.size > 0
  end
  

  
  def show
    ap @stats
    puts %Q{ 
      ********************************
      Total time: #{total_time}
      Total requests: #{@stats.size}
      Total gets: #{total_gets}
      Total creates: #{total_creates}
      Total Opportunity creates: #{total_source_creates("Opportunity")} 
      Total Contact creates: #{total_source_creates("Contact")} 
      Total Activity creates: #{total_source_creates("Activity")}    
      Total Opportunity updates: #{total_source_updates("Opportunity")}  
      Max time: #{max_time}
      Min time: #{min_time}
      Requests per second: #{requests_per_sec}
      ********************************
    }
    
    create_models = ["Opportunity","Contact","Activity"] 
    create_models.each {|model| 
      puts "      ------ Times for create #{model}"
      max_time = total_source_creates_max(model)
      puts "      Max time: #{max_time}"
      min_time = total_source_creates_min(model)
      puts "      Min time: #{min_time}"
      avg_time = total_source_creates_avg(model)
      puts "      Avg time: #{avg_time}"
      puts "      -------------------------------------------"
      puts ""
    }
    
    update_models = ["Opportunity"] 
    update_models.each {|model| 
      puts "      %%%%%%%%%% Times for update #{model}"
      max_time = total_source_updates_max(model)
      puts "      Max time: #{max_time}"
      min_time = total_source_updates_min(model)
      puts "      Min time: #{min_time}"
      avg_time = total_source_updates_avg(model)
      puts "      Avg time: #{avg_time}"
      puts "      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
      puts ""
    }
      
  end
  
  def log_result(user)
    puts "user, total time,total request, total gets, total request"
    
  end
  
  def add(request)
    @stats << request
  end
  
end


# [
#     {
#         :action => "post",
#           :time => 1.338855
#     },
#     {
#         :action => "post",
#           :time => 1.975961
#     },
#     {
#         :action => "post",
#           :time => 0.74427
#     },
#     {
#         :action => "post",
#           :time => 1.411566
#     },
#     {
#         :action => "post",
#           :time => 2.068309
#     },
#     {
#         :action => "post",
#           :time => 0.414528
#     }
# ]
