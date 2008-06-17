require File.expand_path('../test_helper', __FILE__)
require 'shared_passenger_behaviour'

describe "SharedPassengerBehaviour" do
  include SharedPassengerBehaviour
  
  it "should forward commands to be executed with privileges to the SecurityHelper" do
    OSX::SecurityHelper.sharedInstance.expects(:executeCommand_withArgs).with('/some/command', ['arg1', 'arg2'])
    execute '/some/command', 'arg1', 'arg2'
  end
end