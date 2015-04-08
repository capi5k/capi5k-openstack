require 'bundler/setup'
require 'rubygems'
require 'capistrano'
require 'xp5k'
require 'erb'
require 'colored'

load "config/deploy.rb"

desc 'Automatic deployment'
task :automatic do
 puts "Welcome to automatic deployment".bold.blue
end

after "automatic", "xp5k", "puppetcluster", "openstack", "openstack:bootstrap"

# the following images will be uploaded during cap openstack:bootstrap
$images = []
$images << { 
  :name  => "ubuntu-13.10-server-clouding-amd64-disk1.img",
  :url   => "http://public.rennes.grid5000.fr/~msimonin/ubuntu-13.10-server-clouding-amd64-disk1.img", 
  :short => "ubuntu-13.10"
}
