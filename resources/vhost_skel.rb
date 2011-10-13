#
# Cookbook Name:: webapp
# Resource:: vhost_skel
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

actions :create, :delete, :disable, :finalize

attribute :name,              :kind_of => String, :name_attribute => true
attribute :document_root,     :kind_of => String
attribute :host_name,         :kind_of => String
attribute :host_aliases,      :kind_of => Array,  :default => []
attribute :non_ssl_server,    :default => true
attribute :listen_ports,      :kind_of => Array,  :default => [ 80 ]
attribute :www_redirect,      :default => true
attribute :ssl_server,        :default => false
attribute :ssl_listen_ports,  :kind_of => Array,  :default => [ 443 ]
attribute :ssl_www_redirect,  :default => true
attribute :ssl_cert,          :kind_of => String,
  :default => "ssl-cert-snakeoil.pem"
attribute :ssl_key,           :kind_of => String,
  :default => "ssl-cert-snakeoil.key"
attribute :ssl_chain,         :kind_of => String
attribute :vhost_vars,        :kind_of => Hash

def initialize(*args)
  super
  @action = :create
end
