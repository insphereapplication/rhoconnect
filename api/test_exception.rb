set :raise_errors, true
use Rack::Exceptional, 'b8788d7b2ae404c9661f40215f5d9258aede9c83'

Rhosync::Server.api :test_exception do |params,user|
  puts "Raising test exception..."
  
  Exceptional.rescue do
    raise "Raised a test exception from API. Boom."
  end
  
end