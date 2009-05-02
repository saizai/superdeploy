require 'fileutils'

example_deploy = File.join(File.dirname(__FILE__), 'deploy.rb.example')
destination_file = File.join(RAILS_ROOT, 'config', 'deploy.rb.example')

if File.exists? destination_file
  puts "You already have a config/deploy.rb.example file..."
else
  FileUtils.cp example_deploy, destination_file
  puts "SuperDeploy installed. Please edit config/deploy.rb.example"
end