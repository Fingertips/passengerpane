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

class ConfigInstaller
  attr_reader :data
  
  def initialize(yaml_data, extra_command = nil)
    @data = YAML.load(yaml_data)
    @extra_command = extra_command
  end
  
  def add_to_hosts(index)
    host = @data[index]['host']
    OSX::NSLog("Will add host: #{host}")
    system "/usr/bin/dscl localhost -create /Local/Default/Hosts/#{host.bypass_safe_level_1} IPAddress 127.0.0.1"
  end
  
  def create_vhost_conf(index)
    app = @data[index]
    vhost = %{
<VirtualHost *:80>
  ServerName #{app['host']}
  DocumentRoot "#{File.join(app['path'], 'public')}"
  RailsEnv #{app['environment']}
  RailsAllowModRewrite #{app['allow_mod_rewrite'] ? 'on' : 'off'}
</VirtualHost>
}.sub(/^\n/, '')
    
    OSX::NSLog("Will write vhost file: #{app['config_path']}\nData: #{vhost}")
    File.open(app['config_path'].bypass_safe_level_1, 'w') { |f| f << vhost }
  end
  
  # def execute_extra_command
  #   system(@extra_command.bypass_safe_level_1) if @extra_command
  # end
  
  def restart_apache!
    system "/bin/launchctl stop org.apache.httpd"
  end
  
  def install!
    (0..(@data.length - 1)).each do |index|
      add_to_hosts index
      create_vhost_conf index
    end
    #execute_extra_command
    restart_apache!
  end
end

if $0 == __FILE__
  OSX::NSLog("Will try to write config(s).")
  ConfigInstaller.new(*ARGV).install!
end