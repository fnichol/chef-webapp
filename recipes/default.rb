#
# Cookbook Name:: webapp
# Recipe:: default
#
# Copyright 2010, Fletcher Nichol
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

node[:webapp][:apps].each do |app|
  # ensure that this app is using a valid and declared vhost
  unless node[:webapp][:vhosts].map { |v| v[:id] }.include?(app[:vhost])
    msg = "webapp[#{app[:id]}] refers to a vhost '#{app[:vhost]}' "
    msg << "not in the vhosts list."
    abort msg
  end

  # determine appropriate user and group for this app
  app_user = app[:user] || node[:webapp][:default][:user]
  app_group = app[:group] || app[:user] || node[:webapp][:default][:user]

  # create a user account for the app owner
  user_account app_user do
    gid       app_group
    ssh_keys  node[:webapp][:users][app_user][:deploy_keys]
  end

  # include any runtime dependencies for the application, based on profile
  case app[:profile]
  when "rails", "rack"
    include_recipe "rvm_passenger::#{web_server}"

    # add the app owner to the rvm group to manage gems
    group "rvm" do
      members [app_user]
      append  true
    end
  when "php"
    include_recipe "php::php5-fpm"
  end

  webapp_app_skel app[:id] do
    vhost             app[:vhost]             # <- this is required
    profile           app[:profile]           if app[:profile]
    user              app[:user]              if app[:user]
    group             app[:group]             if app[:group]
    mount_path        app[:mount_path]        if app[:mount_path]
    env               app[:env]               if app[:env]
    site_vars         app[:site_vars]         if app[:site_vars]
    action            app[:action].to_sym     if app[:action]
  end
end

node[:webapp][:vhosts].each do |vhost|
    if web_server == "apache2"
      # required for maintenance page and www_redirects
      apache_module "rewrite"

      include_recipe "apache2::mod_ssl" if vhost[:ssl_server]
    end

  webapp_vhost_skel vhost[:id] do
    document_root     vhost[:document_root]     if vhost[:document_root]
    host_name         vhost[:host_name]         if vhost[:host_name]
    host_aliases      vhost[:host_aliases]      if vhost[:host_aliases]
    non_ssl_server    vhost[:non_ssl_server]    unless vhost[:non_ssl_server].nil?
    listen_ports      vhost[:listen_ports]      if vhost[:listen_ports]
    www_redirect      vhost[:www_redirect]      unless vhost[:www_redirect].nil?
    ssl_server        vhost[:ssl_server]        unless vhost[:ssl_server].nil?
    ssl_listen_ports  vhost[:ssl_listen_ports]  if vhost[:ssl_listen_ports]
    ssl_www_redirect  vhost[:ssl_www_redirect]  unless vhost[:ssl_www_redirect].nil?
    ssl_cert          vhost[:ssl_cert]          if vhost[:ssl_cert]
    ssl_key           vhost[:ssl_key]           if vhost[:ssl_key]
    vhost_vars        vhost[:vhost_vars]        if vhost[:vhost_vars]
    action            vhost[:action].to_sym     if vhost[:action]
  end
end
