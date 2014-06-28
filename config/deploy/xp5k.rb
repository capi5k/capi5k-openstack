require 'bundler/setup'
require 'rubygems'
require 'xp5k'
require 'erb'

# G5K global parameters
set :site, ENV['site'] || "nantes"
set :walltime, ENV['walltime'] || "02:00:00"
set :subnet, ENV['subnet'] || "slash_18"
set :vlan, ENV['vlan'] || "21"


XP5K::Config.load

$myxp = XP5K::XP.new(:logger => logger)

$myxp.define_job({
  :resources  => ["{type='kavlan-global'}/vlan=1, nodes=5, walltime=#{walltime}"],
  :site       => "#{site}",
  :retry      => true,
  :goal       => "100%",
  :types      => ["deploy"],
  :name       => "init" , 
  :roles      =>  [
    XP5K::Role.new({ :name => 'capi5k-init', :size => 5 }),
  ],

  :command    => "sleep 86400"
})

$myxp.define_deployment({
  :site           => "#{site}",
  :environment    => "ubuntu-x64-1204",
  :roles          => %w(capi5k-init),
  :vlan           => "#{vlan}",
  :key            => File.read("#{ssh_public}"), 
})

load "config/deploy/xp5k_common_tasks.rb"
