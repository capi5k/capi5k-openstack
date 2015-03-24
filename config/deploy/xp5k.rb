require 'bundler/setup'
require 'rubygems'
require 'xp5k'
require 'erb'

XP5K::Config.load

XP5K::Config[:jobname]  ||= 'openstack'
XP5K::Config[:site]     ||= 'lyon'
XP5K::Config[:walltime] ||= '3:00:00'
XP5K::Config[:nodes]    ||= 5

$myxp = XP5K::XP.new(:logger => logger)

$myxp.define_job({
  :resources  => ["{type='kavlan'}/vlan=1, {virtual!='none'}/nodes=#{XP5K::Config[:nodes]}, walltime=#{XP5K::Config[:walltime]}"],
  :site       => "#{XP5K::Config[:site]}",
  :retry      => true,
  :goal       => "100%",
  :types      => ["deploy"],
  :name       => "#{XP5K::Config[:jobname]}", 
  :roles      =>  [
    XP5K::Role.new({ :name => 'capi5k-init', :size => 5 }),
  ],

  :command    => "sleep 206400"
})

$myxp.define_deployment({
  :site           => "#{XP5K::Config[:site]}",
  :environment    => "ubuntu-x64-1204",
  :roles          => %w(capi5k-init),
  :key            => File.read("#{ssh_public}"), 
  :vlan_from_job  => "#{XP5K::Config[:jobname]}",
})

load "config/deploy/xp5k_common_tasks.rb"
