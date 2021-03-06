# author: Ghada Moualla - ghada.moualla@inria.fr
namespace :sahara do
  
  desc 'Deploy sahara on the controller node'
  task :default do
    install
    configure
    configure_horizon
    restart_nova
    start
  end

  task :install, :roles => [:controller] do
    set :user, "root"
    run "apt-get install -y python-pip"
    run "pip install MySQL-python"
    run "apt-get install -y python-pip libmysqlclient-dev python-dev"
    # prevent from upgrading oslo the a newer version (something is wrong since 1.10.0)
    run "#{proxy} pip install oslo.db==1.9.0"
    run "#{proxy} pip install sahara==2014.2.1"
    run "#{proxy} pip install sahara-dashboard==2014.1.3"
  end
  
  task :configure, :roles => [:controller], :on_error => [:continue] do
    set :default_environment, rc('admin')
    set :default_environment, {
      "OS_USERNAME" => "admin",
      "OS_PASSWORD" => "fyby-tet",
      "OS_TENANT_NAME" => "admin",
      "OS_AUTH_URL" => "http://localhost:5000/v2.0/"
    }
    set :user, "root"

    controller = (find_servers :roles => [:controller]).first.host
    run "mkdir -p  /etc/sahara"
    upload "#{openstack_path}/recipes/sahara_files/sahara.conf", "/etc/sahara/sahara.conf", :via => :scp
    run "mysql -u root -e 'CREATE DATABASE IF NOT EXISTS sahara;'"
    run "sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head"
    run "keystone service-create --name sahara --type data_processing --description 'Data Processing Service'"
    run "keystone endpoint-create --service sahara --publicurl http://#{controller}:8386/v1.1/%\\(tenant_id\\)s --internalurl http://#{controller}:8386/v1.1/%\\(tenant_id\\)s  --adminurl http://#{controller}:8386/v1.1/%\\(tenant_id\\)s  --region openstack"
  end

  task :configure_horizon, :roles => [:controller] do
    set :user, "root"
    upload "#{openstack_path}/recipes/sahara_files/settings.py", "/usr/share/openstack-dashboard/openstack_dashboard/settings.py", :via => :scp
    run "service apache2 restart"
  end

  task :restart_nova, :roles => [:controller] do 
    set :user, "root"
    # it seems that installing sahara breaks oslo.i18n intergration
    # restarting nova-scheduler seems to do the job...
    run "service nova-scheduler restart"
  end

  task :start, :roles => [:controller] do
    set :user, "root"
    run "nohup sahara-all --config-file /etc/sahara/sahara.conf 2> /tmp/sahara.err > /tmp/sahara.out &"
  end

end
