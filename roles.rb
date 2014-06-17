# define your roles here as methods  (this allow roles to be overwritten)
#
# follow the convention :
#
# def role_myrole 
#   $myxp.get_deployed_nodes('myxprole')
# end
#
#

def role_controller
  translate_vlan($myxp.get_deployed_nodes('capi5k-init')[1], "#{vlan}")
end

def role_storage
  translate_vlan($myxp.get_deployed_nodes('capi5k-init')[2], "#{vlan}")
end

def role_compute
  translate_vlan($myxp.get_deployed_nodes('capi5k-init').slice(3..-1), "#{vlan}")
end

def role_openstack
  translate_vlan($myxp.get_deployed_nodes('capi5k-init').slice(1..-1), "#{vlan}")
end

