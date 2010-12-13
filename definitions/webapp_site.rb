#
# Cookbook Name:: webapp
# Definition:: webapp_site
# Author:: Fletcher Nichol <fnichol@nichol.ca>
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

define :webapp_site, :profile => "static", :user => nil, :group => nil, 
    :www_redirect => true, :host_name => nil, :host_aliases => [], 
    :listen_ports => nil, :site_vars => nil, :ssh_keys => [],
    :purge => false, :enable => true do

  params[:user] ||= node[:webapp][:default][:user]
  params[:group] ||= params[:user] || node[:webapp][:default][:user]
  params[:listen_ports] ||= node[:webapp][:default][:listen_ports]

  if params[:purge]
    params[:enable] = false
  end

  deploy_to = "/srv/#{params[:name]}"
  deploy_user_home_dir = "/home/#{params[:user]}"

  site_vars = {
      :docroot      => "#{deploy_to}/current/public",
      :app          => params[:name],
      :host_name    => params[:host_name],
      :host_aliases => params[:host_aliases],
      :listen_ports => params[:listen_ports],
      :www_redirect => params[:www_redirect]
  }
  site_vars.merge!(params[:site_vars]) if params[:site_vars]

  template "#{node[:nginx][:dir]}/sites-available/#{params[:name]}.conf" do
    source      "nginx_#{params[:profile]}.conf.erb"
    owner       'root'
    group       'root'
    mode        '0644'
    variables   site_vars

    if File.exists?("#{node[:nginx][:dir]}/sites-enabled/#{params[:name]}.conf")
      notifies :restart, 'service[nginx]'
    end

    if params[:purge]
      action :delete
    end
  end

  user_account params[:user] do
    gid      params[:group]
    ssh_keys params[:ssh_keys]
  end

  [ deploy_to, "#{deploy_to}/shared" ].each do |dir|
    directory dir do
      owner params[:user]
      group params[:group]
      mode '0755'
      recursive true

      if params[:purge]
        action :delete
      end
    end
  end

  link "#{deploy_user_home_dir}/#{app[:id]}" do
    to deploy_to
    owner params[:user]
    group params[:group]
    if params[:enable]
      action :create
    else
      action :delete
    end
  end

  nginx_site "#{app[:id]}.conf" do
    notifies :restart, 'service[nginx]'
    if params[:enable]
      enable true
    else
      enable false
    end
  end
end

