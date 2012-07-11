require 'rubygems'
require 'logger'
require 'rspec'

# Set environment to test
ENV['RHO_ENV'] = 'test'
ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__),'..'))
require "#{ROOT_PATH}/util/config_file"


# Try to load vendor-ed rhoconnect, otherwise load the gem
begin
  require 'vendor/rhoconnect/lib/rhoconnect'
rescue LoadError
  require 'rhoconnect'
  require 'rhoconnect/server'
end

# Load our rhoconnect application
include Rhoconnect
require "#{ROOT_PATH}/application"

require 'rhoconnect/test_methods'
require File.expand_path("#{ROOT_PATH}/boot.rb")

describe "SpecHelper", :shared => true do
  include Rhoconnect::TestMethods
  
  before(:each) do
    Store.db.flushdb
    Application.initializer(ROOT_PATH)
  end
end