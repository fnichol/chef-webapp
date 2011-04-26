#
# Cookbook Name:: webapp
# Provider:: vhost_skel
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

# =========================================================================
# Action implementations
# =========================================================================

action :create do
  docroots_dir  :create
  vhost_conf    :create
  site_enable   :enable
end

action :delete do
  docroots_dir  :create
  vhost_conf    :delete
  site_enable   :disable
end

action :disable do
  docroots_dir  :create
  vhost_conf    :create
  site_enable   :disable
end

action :finalize do
  sanity_check_apps
  cleanup_removed_app_symlinks
  vhost_docroot         :create
  symlink_mounted_apps  :create
end


# =========================================================================
# Action handlers
# =========================================================================

def docroots_dir(exec_action)
  directory docroot_base_path do
    owner       "root"
    group       "root"
    mode        "0755"
    recursive   true
  end
end

##
# Creates/destroys a virtual host web server configuration file.
#
# @params [:create, :delete] desired state of conf file
def vhost_conf(exec_action)
  send "#{web_server}_vhost_conf", exec_action
end

##
# Creates/destroys an apache2 virtual host configuration file.
#
# @params [:create, :delete] desired state of conf file
def apache2_vhost_conf(exec_action)
  template ::File.join(sites_available_path, "#{new_resource.name}.conf") do
    source      "apache2_vhost.conf.erb"
    cookbook    'webapp'
    owner       'root'
    group       'root'
    mode        '0644'
    variables   vhost_vars
    notifies    :restart, resources(:service => "apache2"), :delayed
    action      exec_action
  end
end

##
# Enables/disables a virtual host for the web application.
#
# @params [:enable, :disable] whether to enable or disable to virtual host
def site_enable(exec_action)
  send "#{web_server}_site_enable", exec_action
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

def sanity_check_apps
  if vhost.has_multiple_root_mounted_apps?
    guilty = vhost.root_mounted_apps.map { |a| a.name }
    msg = "webapp_vhost_skel[#{new_resource.name}] has more than one "
    msg << "application mounted at '/' (#{guilty.join(', ')}). "
    msg << "\nOnly one web application can be mounted as root."
    abort msg
  end
end

def vhost_docroot(exec_action)
  # cleanup any mounted app symlinks
  symlink_mounted_apps :delete

  if vhost.has_root_mounted_app?
    d = directory docroot_path do
      recursive true
      action    :nothing
    end
    d.run_action(:delete) if ::File.directory?(docroot_path)

    f = file ::File.join(partials_path, new_resource.name, "_docroot_stub.conf") do
      action  :nothing
    end
    f.run_action(:delete)

    l = link docroot_path do
      to      ::File.join(node[:webapp][:sites_root],
                vhost.root_mounted_apps.first.name, "current", "public")
      owner   "root"
      group   "root"
      action  :nothing
    end
    l.run_action(:create)
  else
    l = link docroot_path do
      action  :nothing
    end
    l.run_action(:delete) if ::File.symlink?(docroot_path)

    d = directory docroot_path do
      owner       "root"
      group       "root"
      mode        "0755"
      recursive   true
      action      :nothing
    end
    d.run_action(:create)

    t = template ::File.join(partials_path, new_resource.name, "_docroot_stub.conf") do
      source      "apache2_docroot_stub.conf.erb"
      owner       "root"
      group       "root"
      mode        "0755"
      variables   vhost_vars
      action      :nothing
      notifies    :restart, "service[apache2]"
    end
    t.run_action(:create)
  end
end

def cleanup_removed_app_symlinks
  vhost.apps_to_clean.each do |app|
    l = link ::File.join(docroot_path, app.mount_path) do
      action  :nothing
    end
    l.run_action(:delete)
  end
end

def symlink_mounted_apps(exec_action)
  vhost.non_root_mounted_apps.each do |app|
    l = link ::File.join(docroot_path, app.mount_path) do
      to      ::File.join(node[:webapp][:sites_root], app.name,
                "current", "public")
      action  :nothing
    end
    l.run_action(exec_action)
  end
end


# =========================================================================
# Helper methods
# =========================================================================

def vhost
  Webapp::Vhost[new_resource.name]
end

##
# Prepares the hash of vhost paramters.
#
# @return [Hash] the vhost variables hash
def vhost_vars
  case web_server
  when "apache2"
    case node[:platform]
    when "suse"
      # lamesauce! suse (possibly others) have an issue with symlinks
      # in the parent of the Directory:
      # http://www.mail-archive.com/capistrano@googlegroups.com/msg00614.html
      directory_root = docroot_base_path
    else
      directory_root = docroot_path
    end
  when "nginx"
    directory_root = nil
  end

  vhost_vars = {
    :vhost            => new_resource.name,
    :docroot          => docroot_path,
    :directory_root   => directory_root,
    :host_name        => new_resource.host_name ||
                         new_resource.name,
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
                                     new_resource.ssl_key),
    :partials_path    => ::File.join(partials_path, new_resource.name)
  }

  vhost_vars.merge!(new_resource.vhost_vars) if new_resource.vhost_vars
  vhost_vars
end

def docroot_base_path
  ::File.join(node[:webapp][:sites_root], "docroots")
end

def docroot_path
  ::File.join(docroot_base_path, new_resource.name)
end
