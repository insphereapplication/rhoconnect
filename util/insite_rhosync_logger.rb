module Rhosync
  def log(*args)
    InsiteLogger.debug("RhoSync log entry: #{args.join}")
  end
end