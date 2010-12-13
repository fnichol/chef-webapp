#
# Cookbook Name:: webapp
# Recipe:: rack
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

include_recipe "rvm_passenger::nginx"

node[:webapp][:apps].select { |a| a[:profile] == "rack" }.each do |app|

  deploy_to = "/srv/#{app[:id]}"
  deploy_user = app[:user] || node[:webapp][:default][:user]
  deploy_group = app[:group] || app[:user] || node[:webapp][:default][:user]
  deploy_user_home_dir = "/home/#{deploy_user}"

  if app[:www_redirect].nil? || app[:www_redirect] == "yes"
    www_redirect = true
  else
    www_redirect = false
  end
  
  template "#{node[:nginx][:dir]}/sites-available/#{app[:id]}.conf" do
    source "nginx_rack.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      :docroot => "#{deploy_to}/current/public",
      :app => app[:id],
      :host_name => app[:host_name],
      :host_aliases => app[:host_aliases] || [],
      :listen_ports => app[:listen_ports] || node[:webapp][:default][:listen_ports],
      :www_redirect => www_redirect
    )

    if File.exists?("#{node[:nginx][:dir]}/sites-enabled/#{app[:id]}.conf")
      notifies :restart, 'service[nginx]'
    end
  end

  user_account deploy_user do
    gid         deploy_group
    deploy_keys node[:webapp][:users][deploy_user.to_sym][:deploy_keys]
  end

  [ deploy_to, "#{deploy_to}/shared" ].each do |dir|
    directory dir do
      owner deploy_user
      group deploy_group
      mode '0755'
      recursive true
    end
  end

  link "#{deploy_user_home_dir}/#{app[:id]}" do
    to deploy_to
    owner deploy_user
    group deploy_group
    if app[:status].nil? || app[:status] == "enable"
      action :create
    else
      action :delete
    end
  end

  nginx_site "#{app[:id]}.conf" do
    notifies :restart, 'service[nginx]'
    if app[:status].nil? || app[:status] == "enable"
      enable true
    else
      enable false
    end
  end
end

