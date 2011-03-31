#
# Cookbook Name:: webapp
# Provider:: site_skel
#
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2010, 2011, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

action :create do
  site_conf         :create
  deployment_dirs   :create
  app_user_symlinks :create
  site_enable       :enable
end

action :delete do
  site_enable       :disable
  site_conf         :delete
  deployment_dirs   :delete
  app_user_symlinks :delete
end

action :disable do
  site_enable       :disable
  site_conf         :create
  deployment_dirs   :create
  app_user_symlinks :delete
end

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

##
# Resolves the application user that "owns" the web application.
#
# @return [String] the application user
def app_user
  new_resource.user || node[:webapp][:default][:user]
end

##
# Resolves the application group ownership for the web application.
#
# @return [String] the group ownership
def app_group
  new_resource.group || app_user
end

##
# Resolves the base path for the web application.
#
# @return [String] the base path
def deploy_to
  ::File.join(node[:webapp][:sites_root], new_resource.name)
end

##
# Resolves the path to the home dir of the web application user.
#
# @return [String] web application's home path
def deploy_user_home_dir
  "/home/#{app_user}"
end

##
# Prepares the hash of web application site paramters.
#
# @return [Hash] the site variables hash
def site_vars
  case web_server
  when "apache2"
    case node[:platform]
    when "suse"
      # lamesauce! suse (possibly others) have an issue with symlinks
      # in the parent of the Directory:
      # http://www.mail-archive.com/capistrano@googlegroups.com/msg00614.html
      directory_root = ::File.join(deploy_to, "current")
    else
      directory_root = ::File.join(deploy_to, "current", "public")
    end
  when "nginx"
    directory_root = nil
  end

  site_vars = {
      :docroot          => ::File.join(deploy_to, "current", "public"),
      :directory_root   => directory_root
      :app              => new_resource.name,
      :host_name        => new_resource.host_name,
      :host_aliases     => new_resource.host_aliases,
      :listen_ports     => new_resource.listen_ports,
      :ssl_listen_ports => new_resource.ssl_listen_ports,
      :www_redirect     => new_resource.www_redirect,
      :ssl_www_redirect => new_resource.ssl_www_redirect,
      :non_ssl_server   => new_resource.non_ssl_server,
      :ssl_server       => new_resource.ssl_server,
      :ssl_cert         => ::File.join(node[:webapp][:ssl][:certs_dir],
                                       new_resource.ssl_cert),
      :ssl_key          => ::File.join(node[:webapp][:ssl][:keys_dir],
                                       new_resource.ssl_key)
  }
  if new_resource.profile == "rack"
    site_vars[:rack_env]  = new_resource.env || "production"
  elsif new_resource.profile == "rails"
    site_vars[:rails_env] = new_resource.env || "production"
  end
  site_vars.merge!(new_resource.site_vars) if new_resource.site_vars
  site_vars
end

##
# Converges the web application virtual host state. Also, bacon.
#
# @param [:create, :delete] desired state of the virtual host
def site_conf(exec_action)
  send "#{web_server}_site_conf".to_sym, exec_action
end

##
# Converges the web application virtual host state for an nginx host.
#
# @param [:create, :delete] desired state of the virtual host
def nginx_site_conf(exec_action)
  template "#{node[:nginx][:dir]}/sites-available/#{new_resource.name}.conf" do
    source      "nginx_#{new_resource.profile}.conf.erb"
    cookbook    'webapp'
    owner       'root'
    group       'root'
    mode        '0644'
    variables   site_vars
    notifies    :restart, resources(:service => "nginx"), :delayed
    action      exec_action
  end
end

##
# Converges the web application virtual host state for an apache2 host.
#
# @param [:create, :delete] desired state of the virtual host
def apache2_site_conf(exec_action)
  # required for maintenance page and www_redirects
  apache_module "rewrite"

  template "#{node[:apache][:dir]}/sites-available/#{new_resource.name}.conf" do
    source      "apache2_#{new_resource.profile}.conf.erb"
    cookbook    'webapp'
    owner       'root'
    group       'root'
    mode        '0644'
    variables   site_vars
    notifies    :restart, resources(:service => "apache2"), :delayed
    action      exec_action
  end
end

##
# Prepares state of deployment directories for the web application.
#
# @param [:create, :delete] desired state
def deployment_dirs(exec_action)
  [ deploy_to, "#{deploy_to}/shared" ].each do |dir|
    directory dir do
      owner     app_user
      group     app_group
      mode      '2775'
      recursive true
      action    exec_action
    end
  end
end

##
# Prepares state of the convenience symlink for the web application user.
#
# @param [:create, :delete] desired state
def app_user_symlinks(exec_action)
  link "#{deploy_user_home_dir}/#{new_resource.name}" do
    to          deploy_to
    owner       app_user
    group       app_group
    action      exec_action
  end
end

##
# Enables/disables a virtual host for the web application.
#
# @params [:enable, :disable] whether to enable or disable to virtual host
def site_enable(action)
  send "#{web_server}_site_enable", action
end

##
# Enable/disable an nginx site. This was pinched from
# opscode/cookbooks/definitions/nginx_site.rb as definitions cannot be triggered
# on demand.
#
# @param [:enable, :disable] whether to enable or disable the virtual host
def nginx_site_enable(exec_action)
  if exec_action == :enable
    execute "nxensite #{new_resource.name}.conf" do
      command     "/usr/sbin/nxensite #{new_resource.name}.conf"
      notifies    :restart, resources(:service => "nginx"), :delayed
      action      :run
      not_if do
        ::File.symlink?(
          "#{node[:nginx][:dir]}/sites-enabled/#{new_resource.name}.conf")
      end
    end
  else
    execute "nxdissite #{new_resource.name}.conf" do
      command     "/usr/sbin/nxdissite #{new_resource.name}.conf"
      notifies    :restart, resources(:service => "nginx"), :delayed
      action      :run
      only_if do
        ::File.symlink?(
          "#{node[:nginx][:dir]}/sites-enabled/#{new_resource.name}.conf")
      end
    end
  end
end

##
# Enable/disable an apache2 site. This was pinched from
# opscode/cookbooks/apache/definitions/apache_site.rb as definitions cannot
# be triggered on demand.
#
# @param [:enable, :disable] whether to enable or disable the virtual host
def apache2_site_enable(exec_action)
  if exec_action == :enable
    execute "a2ensite #{new_resource.name}.conf" do
      command "/usr/sbin/a2ensite #{new_resource.name}.conf"
      notifies :restart, resources(:service => "apache2")
      not_if do 
        ::File.symlink?("#{node[:apache][:dir]}/sites-enabled/#{new_resource.name}.conf") or
          ::File.symlink?("#{node[:apache][:dir]}/sites-enabled/000-#{new_resource.name}.conf")
      end
      only_if do
        ::File.exists?("#{node[:apache][:dir]}/sites-available/#{new_resource.name}.conf")
      end
    end
  else
    execute "a2dissite #{new_resource.name}.conf" do
      command "/usr/sbin/a2dissite #{new_resource.name}.conf"
      notifies :restart, resources(:service => "apache2")
      only_if do
        ::File.symlink?("#{node[:apache][:dir]}/sites-enabled/#{new_resource.name}.conf")
      end
    end
  end
end
