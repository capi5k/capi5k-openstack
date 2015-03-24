def translate_vlan(nodes, jobname = "-1")
  if (jobname == "-1")
    return nodes
  end

  # get routed local vlan number using the jobname variable
  vlan = $myxp.job_with_name("#{jobname}")['resources_by_type']['vlans'].first.to_i

  to_translate = nodes
  puts to_translate.inspect
  if !nodes.respond_to?('each')
    to_translate = [nodes]
  end
  to_translate.map {|node|
    a = node.split('.')
    a[0] = a[0]+"-kavlan-"+vlan.to_s
    a.join('.')
  }
end
