task :default => :run

task :run do
  sh "xcodebuild"
  sh "open build/Release/Passenger.prefPane"
end

task :clean do
  sh 'rm -rf build/'
  sh 'rm -rf pkg'
end

task :release => :clean do
  require 'osx/cocoa'
  version = OSX::NSDictionary.dictionaryWithContentsOfFile('Info.plist')['CFBundleVersion'].to_s
  name = "PassengerPane-#{version}"
  pkg_dir = "pkg/#{name}"
  
  sh "xcodebuild"
  sh "mkdir -p #{pkg_dir}"
  sh "cp -R build/Release/Passenger.prefPane #{pkg_dir}"
  %w{ LICENSE README.rdoc passenger_pane_config.rb.ports }.each do |file|
    sh "cp #{file} #{pkg_dir}"
  end
  sh "cd pkg/ && tar -czvf #{name}.tgz #{name}/"
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = nil
  t.options = '-rs'
end

desc "Generate Security.framework BridgeSupport file"
task :bridgesupport do
  #sh "gen_bridge_metadata -f Security -e Security.BridgeSupport-exceptions.xml -o Security.bridgesupport"
  sh "gen_bridge_metadata -f Security -o Security.bridgesupport"
end