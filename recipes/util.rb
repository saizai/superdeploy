namespace (:util) do
  desc "Check uptime" 
  task :uptime do
    run "uptime" 
  end

  desc "Check uname" 
  task :uname do
    run "uname -srp" 
  end

  desc "Grep for ruby processes" 
  task :ruby do
    run "ps -ef |grep ruby | grep -v grep" 
  end
  
  desc "Allow mongrel_rails to be sudo-run w/out password by deploy"
  task :deploy_without_password, :except => { :no_release => true }  do
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