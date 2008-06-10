task :default => :run

task :run do
  sh "xcodebuild"
  sh "open build/Release/Passenger.prefPane"
end

task :test do
  Dir.glob("test/*_test.rb").each do |test|
    sh "ruby #{test}"
  end
end

CONF_PATH = "/etc/apache2/users/passenger_apps"

task :install do
  mkdir_p CONF_PATH
  2.times do |i|
    file = "#{CONF_PATH}/test_app_#{i}.vhost.conf"
    File.open(file, "w") do |f|
      f << %{
<VirtualHost *:80>
  ServerName testapp#{i}.example.local
  DocumentRoot "/path/to/test/app/#{i}/public"
</VirtualHost>
}.sub(/^\n/, '')
    end
    sh "cat #{file}"
  end
end

task :remove do
  2.times do |i|
    rm "#{CONF_PATH}/test_app_#{i}.vhost.conf"
  end
end