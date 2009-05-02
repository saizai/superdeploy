namespace :sys do
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

  desc "Copies contents of ssh public keys into authorized_keys file"
  task :ssh_setup do
    sudo "test -d ~/.ssh || mkdir ~/.ssh"
    sudo "chmod 0700 ~/.ssh"    
    put(ssh_options[:keys].collect{|key| File.read(key+'.pub')}.join("\n"),
      File.join('/home', user, '.ssh/authorized_keys'),
      :mode => 0600 )
  end
end