namespace :deploy do
  namespace :mongrel do
    desc "seesaw::bounce the server. Requires 'deploy ALL = NOPASSWD: /usr/bin/mongrel_rails *' in /etc/sudoers"
    task :seesaw, :roles => :app do
      run "cd #{deploy_to}/current && sudo mongrel_rails seesaw::bounce"
    end
    
    desc "Allow mongrel_rails to be sudo-run w/out password by deploy"
    task :setup_sudoers, :except => { :no_release => true }  do
      puts "\n/etc/sudoers before:"
      sudo "cat /etc/sudoers"
      puts "\nChecking /etc/sudoers integrity..."
      sudo "visudo -c"
      puts "\nChecking /etc/sudoers strict integrity..."
      sudo "visudo -cs"
      if (Capistrano::CLI.ui.ask("Modify? ('yes' continues; anything else aborts) ") == "yes")
        sudo "echo '' >> /etc/sudoers"
        sudo "echo '# Allow user #{deploy} to run mongrel_rails under sudo without a password, so we can do passwordless cap deploy' >> /etc/sudoers"
        sudo "echo '#{deploy} ALL = NOPASSWD: /usr/bin/mongrel_rails *' >> /etc/sudoers"
        puts "\n/etc/sudoers after:"
        sudo "cat /etc/sudoers"
        puts "\nChecking /etc/sudoers integrity..."
        sudo "visudo -c"
        puts "\nChecking /etc/sudoers strict integrity..."
        sudo "visudo -cs"
      end
    end
  end
  
  namespace :passenger do
    desc "Restart using Passenger" 
    task :restart, :roles => :app do
      run "touch #{current_path}/tmp/restart.txt" 
    end
  end
  
  namespace :god do
    task :restart, :roles=>:app do
      sudo "/usr/bin/god restart #{application}"
    end
    
    task :status, :roles => :app do
      sudo "/usr/bin/god status"
    end
        
    namespace :starling do
      [ :stop, :start, :restart ].each do |t|
        desc "#{t.to_s.capitalize} starling using god"
        task t, :roles => :app do
          sudo "god #{t.to_s} starling"
        end
      end
    end
    
    namespace :workling do
      [ :stop, :start, :restart ].each do |t|
        desc "#{t.to_s.capitalize} workling using god"
        task t, :roles => :app do
          sudo "god #{t.to_s} #{application}-workling"
        end
      end
    end
  end

  [ :stop, :start, :restart ].each do |t|
    desc "#{t.to_s.capitalize} app using god"
    task t, :roles => :app do
      sudo "god #{t.to_s} #{application}"
    end
  end
  
  desc "like update:migrations, but will take down the app w/ a maintenance page during it"
  task :long_deploy, :roles => :app do
    transaction do
      update_code
      web.disable
      symlink
      migrate
    end
  
    restart
    web.enable
  end
  
  namespace :files do
    desc "Creates symlinked shared/files folder"
    task :symlink, :roles => :app do
      run "rm -rf #{release_path}/public/files"
      run "mkdir -p #{shared_path}/files"
      run "ln -nfs #{shared_path}/files #{release_path}/public/files"
    end
  end

  namespace :configs do
    # Author: Sai Emrys http://saizai.com
    desc "Override config files w/ whatever's in the shared/config path (e.g. passwords, api keys)"
    task :symlink, :roles => :app do         
      # Be extra careful about exposing these
      run "chmod -R go-rwx #{shared_path}/config"
      
      # For all files in the shared config path, symlink in the shared config
  # For some reason, this Dir actually runs on the *local* system rather than the remote. Lame.
  #    Dir[File.join(shared_path, 'config', '**', '*.rb')].each do |c|
  # So here's a hack w/ find to do it the ugly way :(
      config_files = ''
      # Find all regular files (not directories) in the shared config path
      run("find #{shared_path}/config -type f") do |channel, stream, data| 
       config_files << data
      end
      # Extract the names of all config files
      config_files.strip.split("\n").map{|f| f.sub!("#{shared_path}/config/", '')}.each do |c|
        run "ln -sf #{shared_path}/config/#{c} #{release_path}/config/#{c}" # And symlink in the server's version, overwriting (-f) whatever was there
      end
    end
    
    desc 'Create the shared configs directory on the server'
    task :setup, :roles => :app do
      run "mkdir #{shared_path}/config"
      run "chmod -R go-rwx #{shared_path}/config"
    end
  end
end

