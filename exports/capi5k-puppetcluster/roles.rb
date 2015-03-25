# define your roles here as methods  (this allow roles to be overwritten)
#
# follow the convention :
#
# def role_myrole 
#   $myxp.get_deployed_nodes('myxprole')
# end
#
#
def role_puppet_master
  translate_vlan($myxp.get_deployed_nodes('capi5k-init').first, "#{XP5K::Config[:jobname]}")
end

def role_puppet_clients
  translate_vlan($myxp.get_deployed_nodes('capi5k-init').slice(1..-1), "#{XP5K::Config[:jobname]}")
end

def puppet_version
  "3.7.1"
end


