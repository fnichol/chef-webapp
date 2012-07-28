maintainer       "Fletcher Nichol"
maintainer_email "fnichol@nichol.ca"
license          "Apache 2.0"
description      "Installs/Configures hosted web applications"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"

supports "ubuntu"
supports "debian"
supports "suse"

depends "apache2"
depends "nginx"

recommends "rvm"
recommends "rvm_passenger"
recommends "php"

recipe "webapp", "Installs/Configures hosted web applications"
