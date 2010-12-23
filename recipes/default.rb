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

  # disable site before potentially removing files
  if !app[:action].nil? && app[:action] != "create"
    nginx_site "#{app[:id]}.conf" do
      notifies  :restart, 'service[nginx]'
      enable    false 
    end
  end

  webapp_site app[:id] do
    profile         app[:profile]
    user            app_user
    group           app_group
    host_name       app[:host_name]
    host_aliases    app[:host_aliases] || []
    listen_ports    app[:listen_ports]

    if app[:www_redirect] == "delete"
      www_redirect  false 
    end

    unless app[:action].nil?
      action        app[:action].to_sym
    end

    if app[:profile] == "rails"
      env = app[:env] || "production"
      site_vars     :rails_env => env
    elsif app[:profile] == "rack"
      env = app[:env] || "production"
      site_vars     :rack_env => env
    end
  end

  # enable site after potentially creating files
  if app[:action].nil? || app[:action] == "create"
    nginx_site "#{app[:id]}.conf" do
      notifies  :restart, 'service[nginx]'
      enable    true 
    end
  end
end

