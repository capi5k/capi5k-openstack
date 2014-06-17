# define your capistrano roles here.
#
# role :myrole do
#   role_myrole
# end
#
#

role :controller do
  role_controller
end

role :compute do
  role_compute
end

role :storage do
  role_storage
end

role :openstack do
  role_openstack
end


role :frontend do
  "#{site}"
end

