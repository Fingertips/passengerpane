task :default => :run

task :run do
  sh "xcodebuild"
  sh "open build/Release/Passenger.prefPane"
end

desc 'This is the normal way to run the tests. The :test task will run all tests at the same time and fail because of recursive kvc stuff.'
task :test_normal do
  ENV['TRY_TO_RUN_ALL_TESTS_TOGETHER'] = 'false'
  Dir.glob("test/*_test.rb").each do |test|
    sh "ruby #{test}"
  end
end

# This horribly fails due to some recursive kvc stuff.
# 
# If oc_import.rb:501 is patched like so it works:
# 
# def kvc_writer(*args)
#   args.flatten.each do |key|
#     setter = key.to_s + '='
#     #alias_method kvc_internal_setter(key), setter
#     self.class_eval <<-EOE_KVC_WRITER,__FILE__,__LINE__+1
#       def #{kvc_setter_wrapper(key)}(value)
#         willChangeValueForKey('#{key.to_s}')
#         #send('#{kvc_internal_setter(key)}', value)
#         @#{key} = value
#         didChangeValueForKey('#{key.to_s}')
#       end
#     EOE_KVC_WRITER
#     alias_method setter, kvc_setter_wrapper(key)
#   end
# end
require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end
  
desc "Generate Security.framework BridgeSupport file"
task :bridgesupport do
  #sh "gen_bridge_metadata -f Security -e Security.BridgeSupport-exceptions.xml -o Security.bridgesupport"
  sh "gen_bridge_metadata -f Security -o Security.bridgesupport"
end