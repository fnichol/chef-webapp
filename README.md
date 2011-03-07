# Description

# Requirements

## Platform

## Cookbooks

# Recipes

# Attributes

# Usage

# Resources and Providers

## webapp_site_skel

### Actions

Action    |Description                   |Default
----------|------------------------------|-------
create    |Create the resources needed to host a web application with a name and deployment profile.|Yes
delete    |Remove the web application and its stubs.|
disable   |Disable the web application from being able to serve itself.|

### Attributes

Attribute         |Description |Default value
------------------|------------|-------------
name              |**Name attribute:**  A unique identifier for the web application. This will be used for directory naming among other things. |`nil`
profile           |Declare the kind of web application that will be hosted. Current supported profiles are `static`, `rack`, `rails`, and `php`. |`static`
user              |User that will own the web application and possibly control its deployment. |`deploy`
group             |Group that will be used when set ownership on files and directories relating to the web application. |The value of the `user` attribute.
host_name         |The primary host name that will be set in the virtual host configuration. |`node[:fqdn]`
host_aliases      |An array of additonal host name aliases that the web server will respond to. |`[]`
non_ssl_server    |Create a non-SSL virtual host for this web application? |`true`
listen_ports      |An array of non-SSL ports that the web server will listen on for this web application. |`[ 80 ]`
www_redirect      |Create a virtual host that redirects `http://www.<host>` traffic to `http://<host>`? |`true`
ssl_server        |Create an SSL virtual host for this web application? |`false`
ssl_listen_ports  |An array of SSL ports that the web server will listen on for this web application. |`[ 443 ]`
ssl_www_redirect  |Create a virtual host that redirects `https://www.<host>` traffic to `https://<host>`? |`true`
ssl_cert          |The public key for the SSL certificate. |`ssl-cert-snakeoil.pem`
ssl_key           |The private key for the SSL certificate. |`ssl-cert-snakeoil.key`

### Examples

#### A Rack Web Application Skel

    webapp_site_skel "wiki" do
      profile         "rack"
      host_name       "wiki.example.com"
      www_redirect    false
    end

**Note:** Setting `www_redirect` here will prevent the server from responding
to traffic on `http://www.wiki.example.com`.

#### An SSL Rails Application

Here a custom SSL certificate was declared which needs to be supplied to
server by other means. An additional non-SSL listen port of 3000 was also declared.

    webapp_site_skel "redmine" do
      profile         "rails"
      host_name       "pm.example.com"
      listen_ports    [ 80, 3000 ]
      ssl_server      true
      ssl_cert        "ssl-cert-example.com.crt"
      ssl_key         "ssl-cert-example.com.key"
    end

#### A PHP Application

Here is a questionable PHP site that needs to be taken diabled and taken
offline. It also answers to multiple host names and `www.*` prefixes.

    webapp_site_skel "wp" do
      profile         "php"
      host_name       "blog.example.com"
      host_aliases    [ "therealdeal.example.com", "example.com" ]
      user            "php_hack"
      action          :disable
    end

**Note:** Disabling the web application will not delete it but de-register it
from the web server's enabled virtual hosts.

# License and Author

Author:: Fletcher Nichol (<fnichol@nichol.ca>)

Copyright:: 2010, 2011, Fletcher Nichol

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
