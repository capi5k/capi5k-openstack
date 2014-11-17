require 'netaddr'
require 'hiera'
require 'yaml'

set :openstack_path, "."

load "#{openstack_path}/roles.rb"
load "#{openstack_path}/roles_definition.rb"
load "#{openstack_path}/output.rb"

set :proxy, "http_proxy=http://proxy:3128 https_proxy=http://proxy:3128"
set :puppet_p, "#{proxy} puppet"


# return the hash map credentials
def rc(name)
  config = YAML::load_file("#{openstack_path}/hiera/common.yaml")
  user = config["openstack::keystone::users"][name]
  if (user.nil?)
    return {}
  end

  return {
    "OS_USERNAME"            => name,
    "OS_PASSWORD"            => user["password"],
    "OS_TENANT_NAME"         => user["tenant"],
    'OS_AUTH_URL'            => 'http://localhost:5000/v2.0/',
    'OS_REGION_NAME'         => 'openstack',
    'KEYSTONE_ENDPOINT_TYPE' => 'publicURL',
    'NOVA_ENDPOINT_TYPE'     => 'publicURL'
  }
end


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

    task :prepare, :roles => [:puppet_master], :on_error => :continue  do
      set :user, "root"
      run "#{puppet_p} module install puppetlabs-openstack -v 4.2.0"
      upload "#{openstack_path}/openstackg5k", "/etc/puppet/modules", :via => :scp, :recursive => :true
    end 

    desc 'Apply patches'
    task :patchs, :roles => [:puppet_master] do
      set :user, "root"
      upload "#{openstack_path}/patchs/modules", "/etc/puppet/", :via => :scp, :recursive => :true
    end
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
        @allowedHost = @controllerAddress.gsub(/(\d)+\.(\d)+$/, "%.%")
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
      upload("#{openstack_path}/hiera","/etc/puppet", :via => :scp, :recursive => true)
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
#          include openstack::role::storage
        }
      }
      manifest2 = %{}
      compute = find_servers :roles => [:compute]
      compute.each do |c|
        manifest << %{
          node '#{c}' {
            class{'::openstackg5k::role::compute':}
          }
        }
        # we fix the network after the first run
        manifest2 << %{
          node '#{c}' {
            class{'::openstackg5k::profile::nova::nova-legacy-net-compute':}
          }
        }
      end
      File.write('tmp/site.pp', manifest)
      File.write('tmp/site_ntx.pp', manifest2)
    end
    task :transfer, :roles => [:puppet_master] do
      set :user, 'root'
      upload "#{openstack_path}/tmp/site.pp", "/etc/puppet/manifests/", :via => :scp
      upload "#{openstack_path}/tmp/site_ntx.pp", "/etc/puppet/manifests/", :via => :scp
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
      network::default
    end

    desc 'Provision the controller'
    task :controller, :roles => [:controller], :on_error => :continue do
      set :user, "root"
      run "puppet agent -t"
    end

    desc 'Provision the other nodes'
    task :others, :roles => [:compute], :max_hosts => 20, :on_error => :continue do
      set :user, "root"
      run "sleep $(( RANDOM%120 + 1 )) && puppet agent -t"
    end
  
    namespace :network do
      desc 'Install the legacy network'
      task :default do
        network_manifest
        network_apply
      end

      desc 'Path compute site.pp with legacy network recipe'
      task :network_manifest, :roles => [:puppet_master] do
        set :user, "root"
        run "cp /etc/puppet/manifests/site.pp /etc/puppet/manifests/site.pp.old"
        run "cp /etc/puppet/manifests/site_ntx.pp /etc/puppet/manifests/site.pp"
      end

      task :network_apply, :roles => [:compute] do
        set :user, "root"
        run "sleep $(( RANDOM%120 + 1 )) && puppet agent -t"
      end

      desc "Restart compute services (network/compute/cert/api-metadat)"
      task :restart_services, :roles => [:compute], :on_error => :continue do
        set :user, "root"
        run "service nova-compute restart"
        run "service nova-network restart"
        run "service nova-api-metadata restart"
        run "service nova-cert restart"
      end
    end
  end

  namespace :bootstrap do
    desc 'Bootstrap the environment (add image/sec-group/network)' 
    task :default do
      upload_keys
      images
      network
      admin_ec2
      quotas
      demo::default
      ec2_boot
      nova_boot
    end

    task :upload_keys, :roles => [:controller] do
      set :user, "root"
      upload "#{openstack_path}/keys/id_rsa.pub", ".ssh/id_rsa.pub", :via => :scp
      upload "#{openstack_path}/keys/id_rsa", ".ssh/id_rsa", :via => :scp
      run "chmod 600 .ssh/id_rsa"
    end

    task :images, :roles => [:controller] do
      set :default_environment, rc('test')
      set :user, "root"
       $images.each do |image|
        run "wget #{image[:url]} -O #{image[:name]}"
        run "glance add name='#{image[:short]}' is_public=true container_format=ovf disk_format=qcow2 < #{image[:name]}"
        run "nova image-list"
      end
    end

    task :network, :roles => [:controller] do
      set :default_environment, rc('test')
      set :user, "root"
      controllerAddress = capture "facter ipaddress"
      # we choose a range of ips which doen't collide with any host of g5k 
      # see https://www.grid5000.fr/mediawiki/index.php/User:Lnussbaum/Network#KaVLAN
      # here 255 hosts only
      nova_net = controllerAddress.gsub(/(\d)+\.(\d)+$/, "230.0/24")
      run "nova network-create net-jdoe --bridge br100 --multi-host T --fixed-range-v4 #{nova_net}"
      run "nova net-list"
    end

    task :admin_ec2, :roles => [:controller] do
      set :default_environment, rc('test')
      set :user, "root"
      # acces and secret key
      run "keystone ec2-credentials-create > admin.ec2"
      run "cat admin.ec2"
    end

    task :quotas, :roles => [:controller], :on_error => :continue do
      set :default_environment, rc('test')
      set :user, "root"
      # disable quotas
      run "nova quota-class-update --cores -1 default"
      run "nova quota-class-update --instances -1 default"
      run "nova quota-class-update --ram -1 default"
      # run some checks
      run "nova-manage service list | sort"
      puts "### Now creating EC2 credentials"
    end

    namespace :demo do

      desc 'Bootstrap the demo user'
      task :default do
        demorc
        ec2 
      end

      task :demorc, :roles => [:controller] do
        set :user, "root"
        rc = rc("demo")
        run "echo \"\" > demorc" 
        rc.each do |k,v| 
          run "echo \"export #{k}=#{v}\" >> demorc"
        end
      end

      task :ec2, :roles => [:controller] do
        set :user, "root"
        set :default_environment, rc('demo')
        run "nova keypair-add --pub_key /root/.ssh/id_rsa.pub jdoe_key"
        run "nova secgroup-create vm_jdoe_sec_group 'vm_jdoe_sec_group test security group'"
        run "nova secgroup-add-rule vm_jdoe_sec_group tcp 1 65535 0.0.0.0/0"
        run "nova secgroup-add-rule vm_jdoe_sec_group udp 1 65535 0.0.0.0/0"
        run "nova secgroup-add-rule vm_jdoe_sec_group icmp -1 -1 0.0.0.0/0"
        run "nova secgroup-list-rules vm_jdoe_sec_group"
        run "keystone ec2-credentials-create > demo.ec2"
        run "nova secgroup-list"
        run "cat demo.ec2"
      end


    end

    task :ec2_boot, :roles => [:controller] do
      set :user, "root"
      run "cat admin.ec2"
      puts "You can run instances using ec2 : "
      puts "EC2_ACCCESS_KEY=abc EC2_SECRET_KEY=abc EC2_URL=abc euca-run-instances -n 1 -g vm_jdoe_sec_group -k jdoe_key -t m1.medium ubuntu-image"
    end


    desc 'reminder about booting a VMs'
    task :nova_boot do
      puts "You are now ready to boot a VM : (change the net-id) "
      puts "nova boot --flavor 3 --security_groups vm_jdoe_sec_group --image ubuntu-image --nic net-id=a665bfd4-53da-41a8-9bd6-bab03c09b890 --key_name jdoe_key  ubuntu-vm"
    end

  end
end
