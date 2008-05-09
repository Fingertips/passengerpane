#!/usr/bin/env ruby

File.open(ARGV[0], 'w') do |f|
  f << %{
<VirtualHost *:80>
  ServerName #{ARGV[1]}
  DocumentRoot "#{ARGV[2]}"
</VirtualHost>
}.sub(/^\n/, '')
end