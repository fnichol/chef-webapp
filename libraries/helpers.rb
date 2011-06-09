##
# Resolves the web server implementation to use.
#
# @return [String] the web server to target
def web_server
  if %{apache apache2}.include? node[:webapp][:web_server]
    "apache2"
  else
    "nginx"
  end
end

def partials_path
  if web_server == "apache2"
    ::File.join(node[:apache][:dir], "webapp-partials", vhost)
  else
    ::File.join(node[:nginx][:dir], "webapp-partials", vhost)
  end
end

def sites_available_path
  if web_server == "apache2"
    ::File.join(node[:apache][:dir], "sites-available")
  else
    ::File.join(node[:nginx][:dir], "sites-available")
  end
end
