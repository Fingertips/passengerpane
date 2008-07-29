task :default => :run

task :run do
  sh "xcodebuild"
  sh "open build/Release/Passenger.prefPane"
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