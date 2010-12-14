task :default => "prefpane:run"

namespace :prefpane do
  BUILD = "build/Release/Passenger.prefPane"
  BIN = File.join(BUILD, 'Contents/MacOS/Passenger')
  
  desc 'Build the prefpane'
  task :build do
    sh "xcodebuild -configuration Release"
  end
  
  # Make sure that the prefpane searches inside the bundle for the RubyCocoa framework.
  #
  # This task is invoked from the xcode project post build script.
  desc 'Adjusts the install name of the bundled RubyCocoa to point to the right place'
  task :change_ruycocoa_framework_location do
    current = `/usr/bin/otool -L #{BIN}`.match(/^\t(.+RubyCocoa).+$/)[1]
    sh "/usr/bin/install_name_tool -change '#{current}' '@loader_path/../Frameworks/RubyCocoa.framework/Versions/A/RubyCocoa' '#{BIN}'"
  end
  
  desc 'Builds and opens the prefpane'
  task :run => :build do
    sh "open #{BUILD}"
  end
end

desc 'Cleans the build and release pkg'
task :clean do
  sh 'rm -rf build/'
  sh 'rm -rf pkg'
end

desc 'Creates a release build and pkg'
task :release => [:clean, 'prefpane:build'] do
  require 'osx/cocoa'
  version = OSX::NSDictionary.dictionaryWithContentsOfFile('Info.plist')['CFBundleVersion'].to_s
  name = "PassengerPane-#{version}"
  pkg_dir = "pkg/#{name}"
  
  sh "mkdir -p #{pkg_dir}"
  sh "cp -R build/Release/Passenger.prefPane #{pkg_dir}"
  %w{ LICENSE README.rdoc app/config/passenger_pane_config.rb.ports }.each do |file|
    sh "cp #{file} #{pkg_dir}"
  end
  sh "cd pkg/ && tar -czvf #{name}.tgz #{name}/"
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true  
end

desc "Generate Security.framework BridgeSupport file"
task :bridgesupport do
  #sh "gen_bridge_metadata -f Security -e Security.BridgeSupport-exceptions.xml -o Security.bridgesupport"
  sh "gen_bridge_metadata -f Security -o Security.bridgesupport"
end