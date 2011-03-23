require 'rubygems'

# Set environment to test
ENV['RHO_ENV'] = 'test'
ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__),'..'))

# Try to load vendor-ed rhosync, otherwise load the gem
begin
  require 'vendor/rhosync/lib/rhosync'
rescue LoadError
  require 'rhosync'
  require 'rhosync/server'
end

# Load our rhosync application
include Rhosync
require "#{ROOT_PATH}/application"


require 'rhosync/test_methods'

describe "SpecHelper", :shared => true do
  include Rhosync::TestMethods
  
  before(:each) do
    Store.db.flushdb
    Application.initializer(ROOT_PATH)
  end
end