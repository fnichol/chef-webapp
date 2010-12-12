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

node[:webapp].select { |a| a[:profile] == "rack" }.each do |app|

  deploy_to = "/srv/#{app[:id]}"

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

  [ deploy_to, "#{deploy_to}/shared" ].each do |dir|
    directory dir do
      owner app[:user] || node[:webapp][:default][:user]
      group app[:group] || app[:user] || node[:webapp][:default][:user]
      mode '0755'
      recursive true
    end
  end

  nginx_site "#{app[:id]}.conf" do
    notifies :restart, 'service[nginx]'
  end
end

