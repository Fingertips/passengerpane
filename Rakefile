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

desc "Generate Security.framework BridgeSupport file"
task :bridgesupport do
  #sh "gen_bridge_metadata -f Security -e Security.BridgeSupport-exceptions.xml -o Security.bridgesupport"
  sh "gen_bridge_metadata -f Security -o Security.bridgesupport"
end