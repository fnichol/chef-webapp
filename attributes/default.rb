default[:webapp][:apps] = []

default[:webapp][:users][:deploy][:deploy_keys] = []

default[:webapp][:default][:listen_ports] = [ 80 ]
default[:webapp][:default][:ssl_listen_ports] = [ 443 ]
default[:webapp][:default][:user] = "deploy"

default[:webapp][:default][:ssl_cert] = "ssl-cert-snakeoil.pem"
default[:webapp][:default][:ssl_key]  = "ssl-cert-snakeoil.key"
