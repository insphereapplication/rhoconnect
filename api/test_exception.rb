

Rhosync::Server.api :test_exception do |params,user|
  puts "Raising test exception..."
  
  Exceptional.rescue_and_reraise do
    raise "Raised a test exception from API. Boom."
  end
  
end