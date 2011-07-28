require 'rubygems'
require 'logger'
require 'rspec'

# Set environment to test
ENV['RHO_ENV'] = 'test'
ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__),'..'))
require "#{ROOT_PATH}/util/config_file"


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
require File.expand_path("#{ROOT_PATH}/boot.rb")

describe "SpecHelper", :shared => true do
  include Rhosync::TestMethods
  
  before(:each) do
    Store.db.flushdb
    Application.initializer(ROOT_PATH)
  end
end