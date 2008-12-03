#!/usr/bin/env ruby

require 'osx/cocoa'
require 'yaml'
require 'fileutils'
require File.expand_path('../passenger_pane_config', __FILE__)

class String
  def bypass_safe_level_1
    str = dup
    str.untaint
    str
  end
end

class ConfigInstaller
  attr_reader :data
  
  def initialize(yaml_data, extra_command = nil)
    @data = YAML.load(yaml_data)
    @extra_command = extra_command
  end
  
  def add_to_hosts(index)
    server_name = @data[index]['host']
    [server_name, *@data[index]['aliases'].split(' ')].each do |host|
      OSX::NSLog("Will add host: #{host}")
      system "/usr/bin/dscl localhost -create /Local/Default/Hosts/#{host.bypass_safe_level_1} IPAddress 127.0.0.1"
    end
  end
  
  def verify_vhost_conf
    unless File.exist? PassengerPaneConfig::PASSENGER_APPS_DIR
      OSX::NSLog("Will create directory: #{PassengerPaneConfig::PASSENGER_APPS_DIR}")
      FileUtils.mkdir_p PassengerPaneConfig::PASSENGER_APPS_DIR
    end
  end
  
  def verify_httpd_conf
    unless File.read(PassengerPaneConfig::HTTPD_CONF).include? "Include #{PassengerPaneConfig::PASSENGER_APPS_DIR}/*.conf"
      OSX::NSLog("Will try to append passenger pane vhosts conf to: #{PassengerPaneConfig::HTTPD_CONF}")
      File.open(PassengerPaneConfig::HTTPD_CONF, 'a') do |f|
        f << %{

# Added by the Passenger preference pane
# Make sure to include the Passenger configuration (the LoadModule,
# PassengerRoot, and PassengerRuby directives) before this section.
<IfModule passenger_module>
  NameVirtualHost *:80
  <VirtualHost *:80>
    ServerName _default_
  </VirtualHost>
  Include #{PassengerPaneConfig::PASSENGER_APPS_DIR}/*.conf
</IfModule>}
      end
    end
  end
  
  def create_vhost_conf(index)
    app = @data[index]
    public_dir = File.join(app['path'], 'public')
    vhost = [
      "<VirtualHost #{app['vhostname']}>",
      "  ServerName #{app['host']}",
      ("  ServerAlias #{app['aliases']}" unless app['aliases'].empty?),
      "  DocumentRoot \"#{public_dir}\"",
      "  #{app['app_type'].capitalize}Env #{app['environment']}",
      (app['user_defined_data'] unless app['user_defined_data'].empty?),
      "</VirtualHost>"
    ].compact.join("\n")
    
    OSX::NSLog("Will write vhost file: #{app['config_path']}\nData: #{vhost}")
    File.open(app['config_path'].bypass_safe_level_1, 'w') { |f| f << vhost }
  end
  
  def restart_apache!
    system PassengerPaneConfig::APACHE_RESTART_COMMAND
  end
  
  def install!
    verify_vhost_conf
    verify_httpd_conf
    
    (0..(@data.length - 1)).each do |index|
      add_to_hosts index
      create_vhost_conf index
    end
    
    restart_apache!
  end
end

if $0 == __FILE__
  OSX::NSLog("Will try to write config(s).")
  ConfigInstaller.new(*ARGV).install!
end