module Rhoconnect
  def log(*args)
    InsiteLogger.debug("Rhoconnect log entry: #{args.join}")
  end
end