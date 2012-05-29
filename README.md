# DISCLAIMER

The contents of this document are in active development and therefore may not
be entirely accurate.

# Description

# Requirements

## Chef

## Platform

## Cookbooks

# Installation

Depending on the situation and use case there are several ways to install
this cookbook. All the methods listed below assume a tagged version release
is the target, but omit the tags to get the head of development. A valid
Chef repository structure like the [Opscode repo][chef_repo] is also assumed.

## Using Librarian

The [Librarian][librarian] gem aims to be Bundler for your Chef cookbooks.
Include a reference to the cookbook in a **Cheffile** and run
`librarian-chef install`. To install with Librarian:

    gem install librarian
    cd chef-repo
    librarian-chef init
    cat >> Cheffile <<END_OF_CHEFFILE
    cookbook 'webapp',
      :git => 'git://github.com/fnichol/chef-webapp.git', :ref => 'v0.2.0'
    END_OF_CHEFFILE
    librarian-chef install

## Using knife-github-cookbooks

The [knife-github-cookbooks][kgc] gem is a plugin for *knife* that supports
installing cookbooks directly from a GitHub repository. To install with the
plugin:

    gem install knife-github-cookbooks
    cd chef-repo
    knife cookbook github install fnichol/chef-webapp/v0.2.0

## As a Git Submodule

A common practice (which is getting dated) is to add cookbooks as Git
submodules. This is accomplishes like so:

    cd chef-repo
    git submodule add git://github.com/fnichol/chef-webapp.git cookbooks/webapp
    git submodule init && git submodule update

**Note:** the head of development will be linked here, not a tagged release.

## As a Tarball

If the cookbook needs to downloaded temporarily just to be uploaded to a Chef
Server or Opscode Hosted Chef, then a tarball installation might fit the bill:

    cd chef-repo/cookbooks
    curl -Ls https://github.com/fnichol/chef-webapp/tarball/v0.2.4 | tar xfz - && \
      mv fnichol-chef-webapp-* webapp

# Usage

# Recipes

## default

# Attributes

## vhosts

## apps

## web\_server

## sites\_root

## ssl/certs\_dir

## ssl/keys\_dir

## default/user

## users

# Resources and Providers

## webapp\_app\_skel

### Actions

Action    |Description                   |Default
----------|------------------------------|-------
create    ||Yes
delete    ||
disable   ||

### Attributes

Attribute         |Description |Default value
------------------|------------|-------------

### Examples

Coming soon...

## webapp\_vhost\_skel

### Actions

Action    |Description                   |Default
----------|------------------------------|-------
create    ||Yes
delete    ||
disable   ||
finalize  ||

### Attributes

Attribute         |Description |Default value
------------------|------------|-------------

### Examples

Coming soon...

## webapp_site_skel (out of date)

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

# Development

* Source hosted at [GitHub][repo]
* Report issues/Questions/Feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make.

# License and Author

Author:: [Fletcher Nichol][fnichol] (<fnichol@nichol.ca>) [![endorse](http://api.coderwall.com/fnichol/endorsecount.png)](http://coderwall.com/fnichol)

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

[repo]:         https://github.com/fnichol/chef-webapp
[issues]:       https://github.com/fnichol/chef-webapp/issues
