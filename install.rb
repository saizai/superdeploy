require 'capistrano'
require 'fileutils'

example_deploy = File.join(File.dirname(__FILE__), 'deploy.rb.example')
real_deploy = File.join(RAILS_ROOT, 'config', 'deploy.rb')
real_example = File.join(RAILS_ROOT, 'config', 'deploy.rb.example')
gemfile = File.join(RAILS_ROOT, 'Gemfile')
capfile = File.join(RAILS_ROOT, 'Capfile')

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

capified_ok = system(capify_cmd)

if capified_ok
  open(capfile, 'a') do |f|
    yes_require = "\nrequire 'bundler/capistrano'"
    no_require = "\n# require 'bundler/capistrano' # Uncomment this in case you want to use bundler deploy tasks"

    f << File.exists?(gemfile) ? yes_require : no_require
  end
end
