#
# Cookbook Name:: webapp
# Provider:: app_skel
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
  deployment_dirs   :create
  app_partial_conf  :create
  app_user_symlinks :create
  register_app_with_vhost
end

action :delete do
  deployment_dirs   :delete
  app_partial_conf  :delete
  app_user_symlinks :delete
  remove_app_from_vhost
end

action :disable do
  deployment_dirs   :create
  app_partial_conf  :delete
  app_user_symlinks :delete
  remove_app_from_vhost
end


# =========================================================================
# Action handlers
# =========================================================================

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
# Converges the web application virtual host state. Also, bacon.
#
# @param [:create, :delete] desired state of the virtual host
def app_partial_conf(exec_action)
  directory partials_path do
    owner     "root"
    group     "root"
    mode      '0755'
    recursive true
    action    :create
  end

  template ::File.join(partials_path, "#{new_resource.name}.conf") do
    source      "#{web_server}_partial_#{new_resource.profile}.conf.erb"
    cookbook    'webapp'
    owner       'root'
    group       'root'
    mode        '0644'
    variables   site_vars
    notifies    :restart, resources(:service => web_server), :delayed
    action      exec_action
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

def register_app_with_vhost
  ruby_block "Register app[#{new_resource.name}] with vhost[#{vhost}]" do
    block do
      Webapp::Vhost.register vhost,
        :name => new_resource.name, :profile => new_resource.profile,
        :mount_path => new_resource.mount_path, :env => new_resource.env
    end

    notifies :finalize, resources(:webapp_vhost_skel => vhost), :delayed
  end
end

def remove_app_from_vhost
  ruby_block "Remove app[#{new_resource.name}] from vhost[#{vhost}]" do
    block do
      Webapp::Vhost.remove vhost,
        :name => new_resource.name, :profile => new_resource.profile,
        :mount_path => new_resource.mount_path, :env => new_resource.env
    end

    notifies :finalize, resources(:webapp_vhost_skel => vhost), :delayed
  end
end


# =========================================================================
# Helper methods
# =========================================================================

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

def vhost
  new_resource.vhost
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
      directory_root = deploy_to
    else
      directory_root = ::File.join(deploy_to, "current", "public")
    end
  when "nginx"
    directory_root = nil
  end

  site_vars = {
      :docroot          => ::File.join(deploy_to, "current", "public"),
      :directory_root   => directory_root,
      :app              => new_resource.name,
      :vhost            => vhost,
      :mount_path       => new_resource.mount_path
  }
  if new_resource.profile == "rack"
    site_vars[:rack_env]  = new_resource.env || "production"
  elsif new_resource.profile == "rails"
    site_vars[:rails_env] = new_resource.env || "production"
  end

  site_vars.merge!(new_resource.site_vars) if new_resource.site_vars
  site_vars
end

def partials_path
  if web_server == "apache2"
    ::File.join(node[:apache][:dir], "webapp-partials", vhost)
  else
    ::File.join(node[:nginx][:dir], "webapp-partials", vhost)
  end
end
