require File.expand_path('../test_helper', __FILE__)
require 'shared_passenger_behaviour'

class PrefPanePassenger
  class << self
    attr_accessor :sharedInstance
  end
end

describe "SharedPassengerBehaviour" do
  include SharedPassengerBehaviour
  
  it "should forward commands to be executed with privileges to the SecurityHelper" do
    OSX::SecurityHelper.sharedInstance.expects(:executeCommand_withArgs).with('/some/command', ['arg1', 'arg2']).returns(1)
    execute('/some/command', 'arg1', 'arg2').should.be true
  end
  
  it "should show an alert if something went wrong while executing the given command" do
    pref_stub = stub('PrefPanePassenger')
    PrefPanePassenger.sharedInstance = pref_stub
    mainView_stub = stub('MainView')
    pref_stub.stubs(:mainView).returns(mainView_stub)
    window_stub = stub('Window')
    mainView_stub.stubs(:window).returns(window_stub)
    
    OSX::SecurityHelper.sharedInstance.stubs(:executeCommand_withArgs).returns(0)
    
    OSX::NSAlert.any_instance.expects(:objc_send).with(
      :beginSheetModalForWindow, window_stub,
      :modalDelegate, nil,
      :didEndSelector, nil,
      :contextInfo, nil
    ).times(1)
    
    execute('/some/command', 'arg1', 'arg2').should.be false
  end
end