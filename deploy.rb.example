# Application
set :application, "my_fancy_app"  # Required

# Repo
set :scm, :git # :git, :darcs, :subversion, :cvs
# set :svn, /path/to/svn # or :darcs or :cvs or :git; defaults to checking PATH
set :repository, "git://github.com/you/fancy_app.git"

# Server
# set :gateway, "gate.host.com" # for the paranoid sysadmins who require a gateway server
set :user, "you" # The user you log in as
set :runner, "#{user}" # The user you want to run things as (if different, set up your sudoers file)
set :deploy_to, "/home/#{user}/#{application}/" # where you want the app deployed. Must be path from root.
# default_run_options[:pty] = true  # Uncomment if on SunOS (eg Joyent) - http://groups.google.com/group/capistrano/browse_thread/thread/13b029f75b61c09d
# set :use_sudo, false # Uncomment if eg you run on a shared host like DreamHost
# ssh_options[:keys] = %w(~/.ssh/sekrit_deploy_key) # You really should use public keys. It's much easier. Make sure it works on your repo too.
# ssh_options[:port] = 25
# set :ip, '##.##.##.##' # IP of repository. Better than using DNS lookups, if it's static

# :no_release => true means that no code will be deployed to that box (but non-code tasks may run on it)
# :primary => true is mostly unused, but could eg be for primary vs slave db servers
# You can have multiple server and/or role lines, but it's cleaner to stick to one or the other format
#server "#{ip}", :app, :db, :web, :primary => true # Single box that does it all
#role :app, "your app-server here"
#role :web, "your web-server here"
#role :db,  "your db-server here", :primary => true, :no_release => true


# desc "Act on staging (e.g. cap staging deploy)"
# task :staging do
#  # These will override any of the above default settings. 
#  # Useful for when you have multiple deploy targets (e.g. production, qa, staging, hotswap).
#  # Only one at a time, though, and make a new task for each target.
#
#  # If you're paranoid, you might want to make all role/server settings wrapped in a setup task like this
#  #  so that it's always explicit what server(s) you're acting on.
#
#  role :db, "staging.foo.com", :no_release => true
#  role :web, "staging.foo.com"
#  role :app, "staging.foo.com"
#  ssh_options[:keys] = %w(~/.ssh/slightly_sekrit_staging_key)
#
#  # Whatever else you might need to set up that's special for this deployment should be linked in like so:
#  after "deploy:set_permissions", "deploy:set_permissions_staging"
# end


# Choose your default deploy methods (run cap -T deploy to see your options)
namespace (:deploy) do
  task :restart, :roles => :app do
    # deploy.mongrel.seesaw
    # deploy.god.restart
    deploy.passenger.restart
  end
  
  # Use a shared config directory. Run cap deploy:configs:setup first.
  # If you do this, be sure to also ensure that all your sekrit config files are in your .gitignore or svn:ignore
  # e.g.: echo 'config/initializers/*_keys.rb' >> .gitignore  
  after "deploy:update_code", "deploy:configs:symlink"
  # Use shared files directory (eg for uploads)
  after "deploy:update_code", "deploy:files:symlink"

  # Set up special permissions
#  after "deploy:update_code", "deploy:set_permissions_staging"
#  task :set_permissions_staging, :except => { :no_release => true } do 
#      run "rm -f #{release_path}/config/database.yml"
#      run "cp #{deploy_to}/shared/config/database.yml #{release_path}/config"
#      run "chmod 775 #{release_path}/config/database.yml"
#  end  
end
