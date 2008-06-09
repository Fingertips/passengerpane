#!/usr/bin/env ruby

vhost_file, hosts_file, host, app_path = ARGV

File.open(vhost_file, 'w') do |f|
  f << %{
<VirtualHost *:80>
  ServerName #{host}
  DocumentRoot "#{File.join(app_path, 'public')}"
</VirtualHost>
}.sub(/^\n/, '')
end

current_hosts = File.read(hosts_file)
File.open(hosts_file, 'w') do |f|
  f << "#{current_hosts}\n127.0.0.1\t\t\t#{host}"
end