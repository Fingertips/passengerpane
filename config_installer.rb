#!/usr/bin/env ruby

require File.expand_path('../file_backup_and_open', __FILE__)

vhost_file, hosts_file, host, app_path = ARGV

vhost = %{
<VirtualHost *:80>
  ServerName #{host}
  DocumentRoot "#{File.join(app_path, 'public')}"
</VirtualHost>
}.sub(/^\n/, '')

File.backup_and_open(vhost_file, 'w', vhost)
File.backup_and_open(hosts_file, 'a', "\n127.0.0.1\t\t\t#{host}")