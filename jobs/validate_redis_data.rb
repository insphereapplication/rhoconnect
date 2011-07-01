app_path = File.expand_path(File.join(File.dirname(__FILE__))) 
require "#{app_path}/../tasks/data_validation"

puts "\n*************Start validating Redis data against CRM:"

DataValidation.validate

puts "Done!!!!!!!!!!!!!\n\n"