require File.expand_path('../test_helper', __FILE__)
require 'PassengerApplication'

describe "PassengerApplication" do
  tests PassengerApplication
  
  def after_setup
    @vhost = File.expand_path('../fixtures/blog.vhost.conf', __FILE__)
    @instance_to_be_tested = PassengerApplication.alloc.initWithFile(@vhost)
  end
  
  it "should initialize with empty path & host" do
    new_app = PassengerApplication.alloc.init
    new_app.path.should == ''
    new_app.host.should == ''
  end
  
  it "should parse the correct host & path from a vhost file" do
    passenger_app.host.should == "het-manfreds-blog.local"
    passenger_app.path.should == "/Users/het-manfred/rails code/blog"
  end
  
  it "should be able to execute shell with administrator permissions" do
    osa = mock('NSAppleScript')
    OSX::NSAppleScript.any_instance.expects(:initWithSource).with('do shell script "/requires/admin/privileges" with administrator privileges').returns(osa)
    osa.expects(:performSelector_withObject).with("executeAndReturnError:", nil)
    
    passenger_app.send(:execute, '/requires/admin/privileges')
  end
  
  it "should return the path to the config file" do
    passenger_app.config_path.should == File.join(PassengerApplication::CONFIG_PATH, "het-manfreds-blog.local.vhost.conf")
  end
  
  it "should be able to save the config file" do
    passenger_app.expects(:execute).with("/usr/bin/env ruby '#{PassengerApplication::CONFIG_INSTALLER}' '#{passenger_app.config_path}' 'het-manfreds-blog.local' '/Users/het-manfred/rails code/blog'")
    passenger_app.save_config!
  end
end