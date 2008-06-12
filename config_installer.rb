#!/usr/bin/env ruby

require 'osx/cocoa'
require File.expand_path('../file_backup_and_open', __FILE__)

vhost_file, hosts_file, host, app_path = ARGV

vhost = %{
<VirtualHost *:80>
  ServerName #{host}
  DocumentRoot "#{File.join(app_path, 'public')}"
</VirtualHost>
}.sub(/^\n/, '')

OSX::NSLog("Will write file: #{vhost_file}\nData: #{vhost}")
File.backup_and_open(vhost_file, 'w', vhost)

OSX::NSLog("Will append to file: #{hosts_file}\nData: #{host}")
File.backup_and_open(hosts_file, 'a', "\n127.0.0.1\t\t\t#{host}")