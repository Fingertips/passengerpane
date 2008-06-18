#!/usr/bin/env ruby

require 'osx/cocoa'
require 'yaml'

class String
  def bypass_safe_level_1
    str = dup
    str.untaint
    str
  end
end

class ConfigUninstaller
  attr_reader :data
  
  def initialize(yaml_data)
    @data = YAML.load(yaml_data)
  end
  
  def remove_from_hosts(index)
    host = @data[index]['host']
    OSX::NSLog("Will remove host: #{host}")
    system "/usr/bin/dscl localhost -delete /Local/Default/Hosts/#{host.bypass_safe_level_1}"
  end
  
  def remove_vhost_conf(index)
    OSX::NSLog("Will remove vhost file: #{config_path(index)}")
    File.delete config_path(index)
  end
  
  def config_path(index)
    "/private/etc/apache2/passenger_vhosts/#{@data[index]['host'].bypass_safe_level_1}.vhost.conf"
  end
  
  def restart_apache!
    system "/bin/launchctl stop org.apache.httpd"
  end
  
  def uninstall!
    (0..(@data.length - 1)).each do |index|
      remove_from_hosts index
      remove_vhost_conf index
    end
    restart_apache!
  end
end

if $0 == __FILE__
  OSX::NSLog("Will try to remove config(s).")
  ConfigUninstaller.new(ARGV.first).uninstall!
end