#!/usr/bin/env ruby

File.open(ARGV[0], 'a') do |f|
  f << %{

LoadModule passenger_module /Library/Ruby/Gems/1.8/gems/passenger-1.0.1/ext/apache2/mod_passenger.so
RailsSpawnServer /Library/Ruby/Gems/1.8/gems/passenger-1.0.1/bin/passenger-spawn-server
RailsRuby /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby
RailsEnv development

Include /private/etc/apache2/users/passenger_apps/*.vhost.conf
}
end