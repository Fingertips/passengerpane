begin
  require 'rubygems'
rescue LoadError
end

require 'test/spec'
require 'mocha'

$SAFE = 1

$:.unshift File.expand_path('../../../lib', __FILE__)
require 'passenger_pane'

$:.unshift(File.expand_path('../test_helper', __FILE__))
require 'collector'
require 'capture_output'
require 'temporary_directory'
require 'fake_apache_directory'
require 'add_allow_switch'

Kernel.add_allow_switch(:system)
Kernel.add_allow_switch(:`)

module Test::Spec::TestCase::InstanceMethods
  include TestHelper::CaptureOutput
  include TestHelper::TemporaryDirectory
  include TestHelper::FakeApacheDirectory
end