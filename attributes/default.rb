default[:webapp][:apps] = []

default[:webapp][:web_server] = "nginx"

default[:webapp][:sites_root] = "/srv"
default[:webapp][:ssl][:certs_dir] = "/etc/ssl/certs"
default[:webapp][:ssl][:keys_dir] = "/etc/ssl/private"

default[:webapp][:default][:user] = "deploy"

default[:webapp][:users][:deploy][:deploy_keys] = []
