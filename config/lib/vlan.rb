def translate_vlan(nodes, vlan = "-1")
  if (vlan == "-1")
    return nodes
  end

  to_translate = nodes
  puts to_translate.inspect
  if !nodes.respond_to?('each')
    to_translate = [nodes]
  end
  to_translate.map {|node|
    a = node.split('.')
    a[0] = a[0]+"-kavlan-#{vlan}"
    a.join('.')
  }
end
