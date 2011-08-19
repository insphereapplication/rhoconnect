class InsiteRackLogger
  def write(s)
    InsiteLogger.debug("Rack log entry: #{s}",{:no_stdout => true})
  end
end