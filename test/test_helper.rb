require 'osx/cocoa'
require 'test/unit'
require 'rubygems' rescue LoadError
require 'test/spec'
require 'mocha'
require 'rucola/test_case'

module Rucola::TestCase::InstanceMethods
  alias_method :pref_pane, :controller
end

$: << File.expand_path('../../', __FILE__)