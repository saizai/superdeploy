# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)

#  desc "An imaginary backup task. (Execute the 'show_tasks' task to display all
#  available tasks.)"
#  task :backup, :roles => :db do #, :only => { :primary => true }
#    # the on_rollback handler is only executed if this task is executed within
#    # a transaction (see below), AND it or a subsequent task fails.
#    on_rollback { delete "/tmp/dump.sql" }
#  
#    run "mysqldump -u theuser -p thedatabase > /tmp/dump.sql" do |ch, stream, out|
#      ch.send_data "thepassword\n" if out =~ /^Enter password:/
#    end
#  end
  
  # Tasks may take advantage of several different helper methods to interact
  # with the remote server(s). These are:
  #
  # * run(command, options={}, &block): execute the given command on all servers
  #   associated with the current task, in parallel. The block, if given, should
  #   accept three parameters: the communication channel, a symbol identifying the
  #   type of stream (:err or :out), and the data. The block is invoked for all
  #   output from the command, allowing you to inspect output and act
  #   accordingly.
  # * sudo(command, options={}, &block): same as run, but it executes the command
  #   via sudo.
  # * delete(path, options={}): deletes the given file or directory from all
  #   associated servers. If :recursive => true is given in the options, the
  #   delete uses "rm -rf" instead of "rm -f".
  # * put(buffer, path, options={}): creates or overwrites a file at "path" on
  #   all associated servers, populating it with the contents of "buffer". You
  #   can specify :mode as an integer value, which will be used to set the mode
  #   on the file.
  # * render(template, options={}) or render(options={}): renders the given
  #   template and returns a string. Alternatively, if the :template key is given,
  #   it will be treated as the contents of the template to render. Any other keys
  #   are treated as local variables, which are made available to the (ERb)
  #   template.
  
#  desc "Demonstrates the various helper methods available to recipes."
#  task :helper_demo do
#    # "setup" is a standard task which sets up the directory structure on the
#    # remote servers. It is a good idea to run the "setup" task at least once
#    # at the beginning of your app's lifetime (it is non-destructive).
#    setup
#  
#    buffer = render("maintenance.rhtml", :deadline => ENV['UNTIL'])
#    put buffer, "#{shared_path}/system/maintenance.html", :mode => 0644
#    sudo "killall -USR1 dispatch.fcgi"
#    run "#{release_path}/script/spin"
#    delete "#{shared_path}/system/maintenance.html"
#  end
