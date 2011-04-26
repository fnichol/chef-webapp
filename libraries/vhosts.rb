module Webapp
  class Vhost
    attr_reader :name, :webapps, :webapps_to_clean

    def initialize(name)
      @name = name
      @webapps = Hash.new
      @webapps_to_clean = Hash.new
    end

    def root_mounted_apps
      @webapps.values.select { |a| a.mount_path.empty? }
    end

    def non_root_mounted_apps
      @webapps.values.select { |a| !a.mount_path.empty? }
    end

    def has_root_mounted_app?
      !root_mounted_apps.empty?
    end

    def has_multiple_root_mounted_apps?
      root_mounted_apps.size > 1
    end

    def apps_to_clean
      @webapps_to_clean.values
    end

    @@vhosts = Hash.new

    def self.register(vhost, opts)
      @@vhosts[vhost] = new(vhost) if @@vhosts[vhost].nil?
      @@vhosts[vhost].webapps[opts[:name]] = App.new(opts)
    end

    def self.remove(vhost, opts)
      @@vhosts[vhost] = new(vhost) if @@vhosts[vhost].nil?
      @@vhosts[vhost].webapps_to_clean[opts[:name]] = App.new(opts)
    end

    def self.registered
      @@vhosts.keys
    end

    def self.[](key)
      @@vhosts[key]
    end
  end

  class App
    attr_reader :name, :profile, :mount_path, :env

    def initialize(opts)
      @name = opts[:name]
      @profile = opts[:profile]
      @mount_path = opts[:mount_path] || ""
      @env = opts[:env]
    end
  end
end
