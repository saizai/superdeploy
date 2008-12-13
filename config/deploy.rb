require 'mongrel_cluster/recipes' # Useful if you run Mongrel
load 'lib/super_deploy.rb' # This line is what triggers the SuperDeploy library

# set :scm, :mercurial # or whatever you like, e.g. :subversion, :git

# URL of repository required
set :repository, "http://your_repo_here"

# application name - i.e. /apps/#{application} - required
set :application, "your_app"

# deploy_to must be path from root
set :deploy_to, "/apps/#{application}"
set :mongrel_conf, "#{deploy_to}/current/config/mongrel_cluster.yml"
set :user, "deploy" # Or as you like. Helpful if it has nopasswd sudo access to run mongrel / etc
set :runner, "deploy"

# set :scm, :darcs               # defaults to :subversion
# set :svn, "/path/to/svn"       # defaults to searching the PATH
# set :darcs, "/path/to/darcs"   # defaults to searching the PATH
# set :cvs, "/path/to/cvs"       # defaults to searching the PATH
# set :gateway, "gate.host.com"  # default to no gateway
# ssh_options[:keys] = %w(/path/to/my/key /path/to/another/key)
# ssh_options[:port] = 25

# :no_release => true means that no code will be deployed to that box
# :primary => true is currently unused, but could eg be for primary vs slave db servers
# you can have multiple "role :foo" lines
role :db, "dbserver1", "dbserver2", :no_release => true
role :web, "webserver1", "webserver2"
role :app, "appserver1", "appserver2"

namespace :deploy do
  after "deploy:update_code", "deploy:set_permissions"
  
  desc "Ensure app's permissions & shared dirs are set correctly."
  task :set_shared, :except => { :no_release => true } do 
    # make sessions shared
    #run "rm -rf #{release_path}/tmp"
    #run "ln -nfs #{shared_path}/tmp #{release_path}/tmp"
    
    # make logfiles shared
    #run "rm -rf #{release_path}/log"
    #run "ln -nfs #{shared_path}/log #{release_path}/log"
  end
end
