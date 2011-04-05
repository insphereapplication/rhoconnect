Rhosync::Server.api :test_exception do |params,user|
  puts "Raising test exception..."
  raise "Raised a test exception from API. Boom."
end