# Use Git for deployment - git-specific options
# default_run_options[:pty] = true
set :scm, "git"
set :repository,  "git://github.com/ajturner/swiftriver.git"
set :branch, "master"
set :deploy_via, :remote_cache
set :git_shallow_clone, 1


set :user,  "root"
set :use_sudo, false
set :runner, nil
# set :group, "wheel"
ssh_options[:keys] = [File.join(ENV["HOME"], ".ec2-ushahidi", "id-ushahidi")]
ssh_options[:compression] = false

set :application, "swiftriver"
set :keep_releases, 3

role :app, "ec2-174-129-89-242.compute-1.amazonaws.com"
role :web, "ec2-174-129-89-242.compute-1.amazonaws.com"
# role :daemons, "ec2-174-129-89-242.compute-1.amazonaws.com"
#role :voip, "voip.votereport.us"
role :db, "ec2-174-129-89-242.compute-1.amazonaws.com", :primary=>true

set :deploy_to, "/var/rails/#{application}"

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

namespace :daemons do
  desc "Start Daemons"
  task :start, :roles => :daemons do
    run "#{deploy_to}/current/script/daemons start"
  end

  desc "Stop Daemons"
  task :stop, :roles => :daemons do
    run "#{deploy_to}/current/script/daemons stop"
    run "sleep 5 && killall -9 ruby"
  end
end

desc "Link in the production database.yml" 
task :after_update_code do
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml" 
end
