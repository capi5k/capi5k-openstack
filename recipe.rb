# change accordingly to your project
#
#
#
#
#set :hadoop_path, "#{recipes_path}/hadoop"

#load "#{hadoop_path}/roles.rb"
#load "#{hadoop_path}/roles_definition.rb"
#load "#{hadoop_path}/output.rb"

# namespace :myproject do
# # your recipe here
# end
require 'netaddr'

set :openstack_path, "."

load "#{openstack_path}/roles.rb"
load "#{openstack_path}/roles_definition.rb"
load "#{openstack_path}/output.rb"

set :proxy, "http_proxy=http://proxy:3128 https_proxy=http://proxy:3128"
set :puppet_p, "#{proxy} puppet"


namespace :openstack do

  desc 'Deploy openstack'
  task :default do
    init::default
    hiera::default
    sitepp::default
    fix_permissions
    run_agents::default
  end

  
  namespace :init do
    desc 'init the puppet module'   
    task :default do
      proxy 
      prepare
      patchs
    end

    # Put it in puppet recipe
    task :init, :roles => [:openstack] do
      set :user, "root"
      upload "#{openstack_path}/templates/gemrc", "/etc/gemrc", :via => :scp
      upload "#{openstack_path}/templates/proxy-guess", "/etc/apt/apt.conf.d/proxy-guess", :via => :scp
    #  upload "#{openstack_path}/templates/puppet.conf", "/etc/puppet/puppet.conf", :via => :scp
    end

    task :prepare, :roles => [:puppet_master] do
      set :user, "root"
      run "#{puppet_p} module install puppetlabs-openstack"
      upload "#{openstack_path}/openstackg5k", "/etc/puppet/modules", :via => :scp, :recursive => :true
    end 

=begin 
    task :patchs, :roles => [:puppet_master] do
      set :user, "root"
      upload "#{openstack_path}/patchs/params.pp", "/etc/puppet/modules/neutron/manifests/params.pp"
      upload "#{openstack_path}/patchs/ovs.pp", "/etc/puppet/modules/neutron/manifests/plugins/ovs.pp"
    end
=end
  end

  namespace :hiera do
    
    desc 'Install the hiera database'
    task :default do
      subnet
      template
      install
    end

    task :subnet, :roles => [:frontend] do
      set :user, "#{g5k_user}"
      puts "#{vlan}"
      b=("#{vlan}".to_i-10)*4+3
      puts b
      @virtualMachineSubnets = (216..255).step(2).to_a.map{|x| "10."+b.to_s+"."+x.to_s+".1/23"} 
      puts @virtualMachineSubnets
      @subnet = @virtualMachineSubnets[0]
      @gateway = "10."+b.to_s+".255.254"
      @dns="131.254.203.235"
      cidr =  NetAddr::CIDR.create(@subnet)
      @ipstart = cidr.first
      @ipend = cidr.last
    end
    
    task :template do
      set :user, "root"
      # get controller address
      controller = find_servers :roles => [:controller]
      @controllerAddress = nil
      controller.each do |c| 
        @controllerAddress = capture "facter ipaddress", :hosts => c
        @controllerAddress = @controllerAddress.gsub("\n", "")
        @allowedHost = @controllerAddress.gsub(/(\d)+$/, "%")
        puts @allowedHost
      end
      storage = find_servers :roles => [:storage]
      @storageAddress = nil
      storage.each do |c| 
        @storageAddress = capture "facter ipaddress", :hosts => c
        @storageAddress = @storageAddress.gsub("\n", "")
      end

      template = File.read("#{openstack_path}/templates/common.yaml.erb")
      renderer = ERB.new(template)
      generate = renderer.result(binding)
      myFile = File.open("#{openstack_path}/hiera/common.yaml", "w")
      myFile.write(generate)
      myFile.close

    end

    task :install, :roles => [:puppet_master] do
      set :user, "root"
      upload("#{openstack_path}/hiera","/etc/puppet/hiera", :via => :scp, :recursive => true)
      run("mv /etc/puppet/hiera/hiera.yaml /etc/puppet/.")
    end

    task :uninstall, :roles => [:puppet_master] do
      set :user, "root"
      run "rm -rf /etc/puppet/hiera"
    end 
  end # hiera

  namespace :sitepp do
  
    desc 'Generate and upload the site.pp'
    task :default do
      generate
      transfer
    end

    task :generate do
      controller = find_servers :roles => [:controller]
      manifest = %{
        node '#{controller.first.host}' {
          include openstackg5k::role::controller
        }
      }
      compute = find_servers :roles => [:compute]
      compute.each do |c|
        manifest << %{
          node '#{compute.first.host}' {
            include openstackg5k::role::compute
          }
        }
      end

      storage = find_servers :roles => [:storage]
      manifest << %{
        node '#{storage.first.host}' {
          include openstack::role::storage
        }
      }
      File.write('tmp/site.pp', manifest)
    end

    task :transfer, :roles => [:puppet_master] do
      set :user, 'root'
      upload "#{openstack_path}/tmp/site.pp", "/etc/puppet/manifests/", :via => :scp
    end

  end # sitepp

  task :fix_permissions, :roles => [:puppet_master] do
    set :user, "root"
    run "chmod 755 -R /etc/puppet"
  end


  namespace :run_agents do
    
    desc "Launch puppet runs on nodes"
    task :default do
      controller
      others
    end

    task :controller, :roles => [:controller] do
      set :user, "root"
      run "puppet agent -t"
    end

    task :others, :roles => [:storage, :compute] do
      set :user, "root"
      run "puppet agent -t"
    end

  end

end

