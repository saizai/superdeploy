require 'capistrano'
require 'fileutils'

example_deploy = File.join(File.dirname(__FILE__), 'deploy.rb.example')
real_deploy = File.join(RAILS_ROOT, 'config', 'deploy.rb')
real_example = File.join(RAILS_ROOT, 'config', 'deploy.rb.example')
gemfile = File.join(RAILS_ROOT, 'Gemfile')

capify_cmd = "capify #{RAILS_ROOT}"

if !File.exists? real_deploy
  FileUtils.cp example_deploy, real_deploy
  puts "SuperDeploy installed. Please edit config/deploy.rb"
elsif !File.exists? real_example
  FileUtils.cp example_deploy, real_example
  puts "SuperDeploy installed. Please edit config/deploy.rb.example"
else
  puts "You already have both config/deploy.rb and config/deploy.rb.example file..."
end

if system(capify_cmd) && File.exists?(gemfile)
  exec 'echo "require \'bundler/capistrano\'" >> Capfile'
else
  exec 'echo "# require \'bundler/capistrano\' # Uncomment this in case you want to use bundler deploy tasks" >> Capfile'
end
