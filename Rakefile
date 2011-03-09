task :default => "test"

desc "Run all tests"
task :test => %w(test:ppane test:passenger_pane)

namespace :ppane do
  desc "Install the Passenger Preference Pane"
  task :install => :build do
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

require 'rake/testtask'
namespace :test do
  Rake::TestTask.new('ppane') do |t|
    t.test_files = FileList['test/ppane/*_test.rb']
    t.verbose = true
  end
  
  desc "Build framework for testing"
  task :build do
    result = `/Developer/usr/bin/xcodebuild -project Passenger.xcodeproj -target PassengerTest`
    puts result unless result.include?('** BUILD SUCCEEDED **')
  end
  
  desc "Run all functional tests for the Passenger Preference Pane"
  task :passenger_pane => :build do
    if File.exist?('/usr/local/bin/nush')
      sh "cd test/passenger_pane; for test in *_test.nu; do /usr/local/bin/nush $test; done"
    else
      puts "[!] Please install Nu to run the functional tests (see doc/DEVELOPMENT)"
    end
  end
end

namespace :xcode do
  desc "Prepares the compiled framework for loading from Nu"
  task :setup_test_framework do
    test_directory  = File.expand_path('../test/passenger_pane', __FILE__)
    framework_name  = ENV['FULL_PRODUCT_NAME']
    framework       = File.join(ENV['BUILT_PRODUCTS_DIR'], framework_name)
    binary          = File.join(ENV['BUILT_PRODUCTS_DIR'], ENV['EXECUTABLE_PATH'])
    
    sh "rm -Rf #{File.join(test_directory, framework_name)}"
    sh "cp -r #{framework} #{test_directory}"
  end
end