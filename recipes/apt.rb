namespace :sys do
  namespace :apt do
    desc "Runs aptitude update on remote server"
    task :update do
      logger.info "Running aptitude update"
      sudo "aptitude update"
    end
  
    desc "Runs aptitude upgrade on remote server"
    task :upgrade do
      sudo_with_input "aptitude upgrade", /^Do you want to continue\?/
    end
  
    desc "Search for aptitude packages on remote server"
    task :search do
      puts "Enter your search term:"
      deb_pkg_term = $stdin.gets.chomp
      logger.info "Running aptitude update"
      sudo "aptitude update"
      stream "aptitude search #{deb_pkg_term}"
    end
  
    desc "Installs a package using the aptitude command on the remote server."
    task :install do
      puts "What is the name of the package(s) you wish to install?"
      deb_pkg_name = $stdin.gets.chomp
      raise "Please specify deb_pkg_name" if deb_pkg_name == ''
      logger.info "Updating packages..."
      sudo "aptitude update"
      logger.info "Installing #{deb_pkg_name}..."
      sudo_with_input "aptitude install #{deb_pkg_name}", /^Do you want to continue\?/
    end
  end
end