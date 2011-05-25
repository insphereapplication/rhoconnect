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
  
  def total_time
    @total_time ||= (end_time - start_time)
  end
  
  def max_time
    @stats.map{|stat| stat[:time]}.max
  end
  
  def min_time
    @stats.map{|stat| stat[:time]}.min
  end
  
  def show
    ap @stats
    puts "Total time: #{total_time}"
    puts "Total requests: #{@stats.size}"
    puts "Max time: #{max_time}"
    puts "Min time: #{min_time}"
    puts "Requests per second: #{requests_per_sec}"
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
