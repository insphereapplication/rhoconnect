module DateUtil
  DEFAULT_TIME_FORMAT = '%Y-%m-%d %H:%M:%S' # YYYY-MM-DD HH:MM:SS
  DATE_PICKER_TIME_FORMAT = '%m/%d/%Y %I:%M %p'
  BIRTHDATE_PICKER_TIME_FORMAT = '%m/%d/%Y'
  HOUR_FORMAT = '%I:%M %p'
  NO_YEAR_FORMAT = '%m/%d %I:%M %p'
  
  class << self    
    def offset
      Time.now.utc_offset
    end
    
    def days_ago(past_date)
      begin
        (Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i
      rescue Exception => e
        puts "Unable to parse days_ago: #{past_date}: #{e}"
      end
    end
    
    def days_ago_relative(past_date)
      begin
        diff = (Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i
        if diff == 0
          "Today"
        else
          "Last Act -#{diff}d"
        end
      rescue Exception => e
        puts "Unable to parse days_ago: #{past_date}: #{e}"
      end
    end
    
    def seconds_until_hour(input_time)
      begin
        (60 - input_time.min)*60
      rescue
        puts "unable to calculate seconds until hour for time #{input_time}"
      end
    end
    
    def date_build(date_string)
      begin
        date = (DateTime.strptime(date_string, DATE_PICKER_TIME_FORMAT))
        date.strftime(DEFAULT_TIME_FORMAT)
      rescue
        puts "Unable to build date"
      end
    end

    def birthdate_build(date_string)
      begin
        date = (DateTime.strptime(date_string, BIRTHDATE_PICKER_TIME_FORMAT))
        date.strftime(DEFAULT_TIME_FORMAT)
      rescue
        puts "Unable to build birthdate"
      end
    end

    def end_date_time(date_string, duration)
      date = (Time.strptime(date_string, DATE_PICKER_TIME_FORMAT))
      end_date = date + (((duration.to_f)*60))
      end_date.strftime(DEFAULT_TIME_FORMAT)
    end
  
    def days_from_now(future_date)
      begin
        (Date.strptime(future_date, DEFAULT_TIME_FORMAT) - Date.today).to_i
      rescue Exception => e
        puts "Unable to process days_from_now: #{future_date}: #{e}"
      end
    end
  
    def days_ago_formatted(past_date)
      begin
        if  (Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i == 0
          return "Today"
        else
          "#{(Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i}d"
        end
      rescue Exception => e
        puts "Unable to parse days_ago_formatted: #{past_date}: #{e}"
      end
    end
    
    def days_calc_formatted(past_date)
      begin
        if  (Date.today - Date.strptime(past_date, DEFAULT_TIME_FORMAT)).to_i == 0
          return "Today"
        else
          "#{(Date.strptime(past_date, DEFAULT_TIME_FORMAT)  - Date.today).to_i}d"
        end
      rescue Exception => e
        puts "Unable to parse days_ago_formatted: #{past_date}: #{e}"
      end
    end
  end
  
end