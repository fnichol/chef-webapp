#
# Cookbook Name:: webapp
# Recipe:: static
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

node[:webapps][:static].each do |app|

  deploy_to = "/srv/#{app[:id]}"
  
  template "#{node[:nginx][:dir]}/sites-available/#{app[:id]}.conf" do
    source "nginx_static.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      :docroot => "#{deploy_to}/current/public",
      :app => app[:id],
      :host_name => app[:host_name],
      :host_aliases => app[:host_aliases] || [],
      :listen_ports => app[:listen_ports] || node[:webapps][:default][:listen_ports],
    )
  end

  [ deploy_to, "#{deploy_to}/shared" ].each do |dir|
    directory dir do
      owner app[:user] || node[:webapps][:default][:user]
      group app[:group] || app[:user] || node[:webapps][:default][:user]
      mode '0755'
      recursive true
    end
  end

  nginx_site "#{app[:id]}.conf" do
    notifies :restart, 'service[nginx]'
  end
end

