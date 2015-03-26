require 'bundler/setup'
require 'rubygems'
require 'xp5k'
require 'erb'

# G5K global parameters
set :site, ENV['site'] || "lyon"
set :walltime, ENV['walltime'] || "3:00:00"
set :subnet, ENV['subnet'] || "slash_18"
set :jobname, ENV['jobname'] || "openstack"
## vlantype values:
# "kavlan"        - routed local vlan
# "kavlan-global" - global vlan
set :vlantype, ENV['vlantype'] || "kavlan"

XP5K::Config.load

$myxp = XP5K::XP.new(:logger => logger)

$myxp.define_job({
  :resources  => ["{type='#{vlantype}'}/vlan=1, {virtual!='none'}/nodes=5, walltime=#{walltime}"],
  :site       => "#{site}",
  :retry      => true,
  :goal       => "100%",
  :types      => ["deploy"],
  :name       => "#{jobname}" ,
  :roles      =>  [
    XP5K::Role.new({ :name => 'capi5k-init', :size => 5 }),
  ],

  :command    => "sleep 206400"
})

$myxp.define_deployment({
  :site           => "#{site}",
  :environment    => "ubuntu-x64-1204",
  :roles          => %w(capi5k-init),
  :vlan_from_job  => "#{jobname}",
  :key            => File.read("#{ssh_public}"), 
})

load "config/deploy/xp5k_common_tasks.rb"
