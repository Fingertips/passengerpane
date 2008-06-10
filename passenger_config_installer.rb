#!/usr/bin/env ruby

require 'fileutils'

conf_path = ARGV[0]
apps_dir = File.join(File.dirname(conf_path), "#{File.basename(conf_path).match(/^(.+?)\.conf$/)[1]}-passenger-apps")

File.open(conf_path, 'a') do |f|
  f << %{

LoadModule passenger_module /Library/Ruby/Gems/1.8/gems/passenger-1.0.1/ext/apache2/mod_passenger.so
RailsSpawnServer /Library/Ruby/Gems/1.8/gems/passenger-1.0.1/bin/passenger-spawn-server
RailsRuby /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby
RailsEnv development

Include #{File.join(apps_dir, '*.vhost.conf')}
}
end

FileUtils.mkdir_p apps_dir