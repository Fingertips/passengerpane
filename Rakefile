task :default => "test"

require 'rake/testtask'
namespace :test do
  Rake::TestTask.new('ppane') do |t|
    t.test_files = FileList['test/ppane/*_test.rb']
    t.verbose = true
  end
  
  desc "Run all functional tests for the Passenger Preference Pane"
  task :passenger_pane do
    if `which nush`.strip != ''
      sh "cd test/passenger_pane; nush  *_test.nu"
    else
      puts "[!] Please install Nu to run the functional tests (see doc/DEVELOPMENT)"
    end
  end
end

desc "Run all tests"
task :test => %w(test:ppane test:passenger_pane)

namespace :ppane do
  desc "Adjusts the install name of the bundled YAML.framework so it can be found by the pane (run from Xcode)"
  task :fix_framework_location do
    directory       = ENV['BUILT_PRODUCTS_DIR']
    binary          = File.join(directory, 'Passenger.prefPane/Contents/MacOS/Passenger')
    executable_path = `/usr/bin/otool -L #{binary}`.match(/^\t(.+YAML)/)[1]
    sh "/usr/bin/install_name_tool -change '#{executable_path}' '#{executable_path.gsub('executable_path', 'loader_path')}' '#{binary}'"
  end
  
  desc "Install the Passenger Preference Pane (run from Xcode)"
  task :install do
    prefpane = File.join(ENV['BUILT_PRODUCTS_DIR'], 'Passenger.prefPane')
    sh "open #{prefpane}"
  end
end

namespace :gem do
  desc "Build the gem"
  task :build do
    sh "gem build ppane.gemspec"
  end
  
  desc "Install the gem"
  task :install => :build do
    if filename = FileList['*.gem'].sort_by { |name| name }.last
      sh "gem install #{filename}"
    end
  end
end

# --- Evaluate

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