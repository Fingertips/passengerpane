#!/usr/bin/env ruby

require 'osx/cocoa'
require File.expand_path('../file_backup_and_open', __FILE__)
require 'yaml'

hosts_file, data, extra_command = ARGV
OSX::NSLog("Will try to write config(s).")

YAML.load(data).each do |app|
  vhost = %{
<VirtualHost *:80>
  ServerName #{app['host']}
  DocumentRoot "#{File.join(app['path'], 'public')}"
  RailsEnv #{app['environment']}
  RailsAllowModRewrite #{app['allow_mod_rewrite'] ? 'on' : 'off'}
</VirtualHost>
}.sub(/^\n/, '')
  
  OSX::NSLog("Will write file: #{app['config_path']}\nData: #{vhost}")
  File.open(app['config_path'], 'w') { |f| f << vhost }
  
  OSX::NSLog("Will append to file: #{hosts_file}\nData: #{app['host']}")
  File.backup_and_open(hosts_file, 'a', "\n127.0.0.1\t\t\t#{app['host']}")
end

system(extra_command) if extra_command