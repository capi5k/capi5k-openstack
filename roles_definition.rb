# define your capistrano roles here.
#
# role :myrole do
#   role_myrole
# end
#
#

role :controller do
  translate_vlan($myxp.get_deployed_nodes('capi5k-init')[1], "#{XP5K::Config[:jobname]}")
end

role :storage do
  translate_vlan($myxp.get_deployed_nodes('capi5k-init')[1], "#{XP5K::Config[:jobname]}")
end

role :compute do
  translate_vlan($myxp.get_deployed_nodes('capi5k-init').slice(2..-1), "#{XP5K::Config[:jobname]}")
end

role :openstack do
  translate_vlan($myxp.get_deployed_nodes('capi5k-init').slice(1..-1), "#{XP5K::Config[:jobname]}")
end


role :frontend do
  "#{XP5K::Config[:site]}"
end

