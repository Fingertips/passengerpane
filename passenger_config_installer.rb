#!/usr/bin/env ruby

require 'fileutils'
require File.expand_path('../file_backup_and_open', __FILE__)

conf_path = ARGV[0]
apps_dir = File.join(File.dirname(conf_path), "#{File.basename(conf_path).match(/^(.+?)\.conf$/)[1]}-passenger-apps")

version = `/usr/bin/gem list passenger`.rstrip.match(/\(([\d\.]+)[,\)]/)[1]
conf = %{

LoadModule passenger_module /Library/Ruby/Gems/1.8/gems/passenger-#{version}/ext/apache2/mod_passenger.so
PassengerRoot /Library/Ruby/Gems/1.8/gems/passenger-#{version}
PassengerRuby /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby

Include #{File.join(apps_dir, '*.vhost.conf')}
}

File.backup_and_open(conf_path.bypass_safe_level_1, 'a', conf)
FileUtils.mkdir_p apps_dir.bypass_safe_level_1