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

CONF_DIR = '/etc/apache2/users/'
task :remove do
  require 'osx/cocoa'
  
  conf = File.join(CONF_DIR, "#{OSX.NSUserName}.conf")
  unless File.exist? "#{conf}.backup" and File.exist? "#{conf}.without-passenger"
    puts "Make sure that both these files exist:\n- #{conf}.backup\n- #{conf}.without-passenger"
    exit 1
  end
  
  dir = File.join(CONF_DIR, "#{OSX.NSUserName}-passenger-apps")
  sh "sudo rm -rf #{dir}" if File.exist? dir
  sh "sudo rm #{conf}" if File.exist? conf
  sh "sudo cp #{conf}.without-passenger #{conf}"
end

task :remove_all => :remove do
  sh "sudo gem uninstall passenger"
end