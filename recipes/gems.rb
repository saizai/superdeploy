namespace :sys do
  namespace :gems do
    desc "List gems on release servers"
    task :list, :roles => :app do
      stream "gem list"
    end
  
    desc "Update all gems on release servers"
    task :update, :roles => :app do
      sudo "gem update"
    end
  
    desc "Install a gem on the release servers"
    task :install, :roles => :app do
      # TODO Figure out how to use Highline with this
      puts "Enter the name of the gem you'd like to install:"
      gem_name = $stdin.gets.chomp
      logger.info "trying to install #{gem_name}"
      sudo "gem install #{gem_name}"
    end
  
    desc "Uninstall a gem from the release servers"
    task :uninstall, :roles => :app do
      puts "Enter the name of the gem you'd like to remove:"
      gem_name = $stdin.gets.chomp
      logger.info "trying to remove #{gem_name}"
      sudo "gem uninstall #{gem_name}"
    end
  end
end