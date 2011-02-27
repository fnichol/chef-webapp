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
    :action => :create, :non_ssl_server => true, :ssl_server => false,
    :ssl_www_redirect => true, :ssl_cert => nil, :ssl_key => nil do

  params[:listen_ports]     ||= node[:webapp][:default][:listen_ports]
  params[:ssl_listen_ports] ||= node[:webapp][:default][:ssl_listen_ports]
  params[:ssl_cert]         ||= node[:webapp][:default][:ssl_cert]
  params[:ssl_key]          ||= node[:webapp][:default][:ssl_key]

  if %w{rails rack}.include?(params[:profile])
    include_recipe "rvm_passenger::nginx"
  elsif %w{php}.include?(params[:profile])
    include_recipe "php::php5-fpm"
  end

  deploy_to = "/srv/#{params[:name]}"
  deploy_user_home_dir = "/home/#{params[:user]}"

  site_vars = {
      :docroot      => "#{deploy_to}/current/public",
      :app          => params[:name],
      :host_name    => params[:host_name],
      :host_aliases => params[:host_aliases],
      :listen_ports => params[:listen_ports],
      :ssl_listen_ports => params[:ssl_listen_ports],
      :www_redirect => params[:www_redirect],
      :ssl_www_redirect => params[:ssl_www_redirect],
      :non_ssl_server   => params[:non_ssl_server],
      :ssl_server       => params[:ssl_server],
      :ssl_cert         => "/etc/ssl/certs/#{params[:ssl_cert]}",
      :ssl_key          => "/etc/ssl/private/#{params[:ssl_key]}"
  }
  site_vars.merge!(params[:site_vars]) if params[:site_vars]

  template "#{node[:nginx][:dir]}/sites-available/#{params[:name]}.conf" do
    source      "nginx_#{params[:profile]}.conf.erb"
    owner       'root'
    group       'root'
    mode        '0644'
    variables   site_vars

    if File.exists?("#{node[:nginx][:dir]}/sites-enabled/#{params[:name]}.conf")
      notifies  :restart, 'service[nginx]'
    end

    if params[:action] == :delete
      action    :delete 
    end
  end

  [ deploy_to, "#{deploy_to}/shared" ].each do |dir|
    directory dir do
      owner     params[:user]
      group     params[:group]
      mode      '2775'
      recursive true

      if params[:action] == :delete
        action  :delete 
      end
    end
  end

  link "#{deploy_user_home_dir}/#{params[:name]}" do
    to deploy_to
    owner params[:user]
    group params[:group]

    if params[:action] == :create
      action :create
    else
      action :delete
    end
  end
end

