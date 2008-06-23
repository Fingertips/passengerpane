require 'osx/cocoa'
require 'test/unit'
require 'rubygems' rescue LoadError
require 'test/spec'
require 'mocha'
require 'rucola/test_case'

module Rucola::TestCase::InstanceMethods
  alias_method :pref_pane, :controller
  alias_method :passenger_app, :controller
end

$: << File.expand_path('../../', __FILE__)

require File.expand_path('../../shared_passenger_behaviour', __FILE__)
module SharedPassengerBehaviour
  # Silencio!
  def p(obj); end
  module_function :p
end

# Silencio!
def OSX.NSLog(*args); end

class OSX::SecurityHelper
  def self.sharedInstance
    @sharedInstance ||= new
  end
  
  def authorizationRef=(ref)
    @authorized = !ref.nil?
  end
  
  def authorized
    @authorized ||= false
  end
  
  def deauthorize
    @authorized = false
  end
  
  def authorized?
    @authorized
  end
end