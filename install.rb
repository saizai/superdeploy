require 'capistrano'
require 'fileutils'

example_deploy = File.join(File.dirname(__FILE__), 'deploy.rb.example')
real_deploy = File.join(RAILS_ROOT, 'config', 'deploy.rb')
real_example = File.join(RAILS_ROOT, 'config', 'deploy.rb.example')

if !File.exists? real_deploy
  FileUtils.cp example_deploy, real_deploy
  puts "SuperDeploy installed. Please edit config/deploy.rb"
elsif !File.exists? real_example
  FileUtils.cp example_deploy, real_example
  puts "SuperDeploy installed. Please edit config/deploy.rb.example"
else
  puts "You already have a config/deploy.rb.example file..."
end

exec "capify #{RAILS_ROOT}"