#!/usr/bin/env ruby

File.open(ARGV[0], 'w') do |f|
  f << %{
<VirtualHost *:80>
  ServerName #{ARGV[1]}
  DocumentRoot "#{File.join(ARGV[2], 'public')}"
</VirtualHost>
}.sub(/^\n/, '')
end