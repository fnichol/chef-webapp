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

  app_user = app[:user] || node[:webapp][:default][:user]
  app_group = app[:group] || app[:user] || node[:webapp][:default][:user]

  user_account app_user do
    gid       app_group
    ssh_keys  node[:webapp][:users][app_user][:deploy_keys]
  end

  group "rvm" do
    members [app_user]
    append  true
  end

  if %w{rails rack}.include?(app[:profile])
    include_recipe "rvm_passenger::#{node[:webapp][:web_server]}"

    # skip generation of ri and rdoc
    cookbook_file "/etc/gemrc" do
      source  "gemrc"
      mode    "0644"
    end
  elsif %w{php}.include?(app[:profile])
    include_recipe "php::php5-fpm"
  end

  webapp_site_skel app[:id] do
    profile           app[:profile]           if app[:profile]
    user              app[:user]              if app[:user]
    group             app[:group]             if app[:group]
    host_name         app[:host_name]         if app[:host_name]
    host_aliases      app[:host_aliases]      if app[:host_aliases]
    non_ssl_server    app[:non_ssl_server]    unless app[:non_ssl_server].nil?
    listen_ports      app[:listen_ports]      if app[:listen_ports]
    www_redirect      app[:www_redirect]      unless app[:www_redirect].nil?
    ssl_server        app[:ssl_server]        unless app[:ssl_server].nil?
    ssl_listen_ports  app[:ssl_listen_ports]  if app[:ssl_listen_ports]
    ssl_www_redirect  app[:ssl_www_redirect]  unless app[:ssl_www_redirect].nil?
    ssl_cert          app[:ssl_cert]          if app[:ssl_cert]
    ssl_key           app[:ssl_key]           if app[:ssl_key]
    env               app[:env]               if app[:env]
    site_vars         app[:site_vars]         if app[:site_vars]
    action            app[:action].to_sym     if app[:action]
  end
end
