require File.expand_path('../test_helper', __FILE__)
require 'PassengerApplication'

describe "PassengerApplication, with a new application" do
  tests PassengerApplication
  
  def after_setup
    @instance_to_be_tested = PassengerApplication.alloc.init
    passenger_app.stubs(:execute)
  end
  
  it "should initialize with empty path & host" do
    passenger_app.path.should == ''
    passenger_app.host.should == ''
    assigns(:dirty).should.be false
    assigns(:new_app).should.be true
  end
  
  it "should not start the application if only one of host or path is entered" do
    passenger_app.expects(:start).times(0)
    
    passenger_app.setValue_forKey('het-manfreds-blog.local', 'host')
    passenger_app.setValue_forKey('', 'host')
    passenger_app.setValue_forKey('/Users/het-manfred/rails code/blog', 'path')
  end
  
  it "should start the application for the first time once a valid host and path are entered" do
    passenger_app.expects(:start).times(1)
    passenger_app.setValue_forKey('het-manfreds-blog.local', 'host')
    passenger_app.setValue_forKey('/Users/het-manfred/rails code/blog', 'path')
  end
  
  it "should start the application by gracefully restarting apache" do
    passenger_app.expects(:save_config!).with('/usr/sbin/apachectl graceful').times(1)
    passenger_app.start
  end
  
  it "should set a default host name if initialized with initWithPath" do
    PassengerApplication.alloc.initWithPath("/some/path/to/RailsApp").host.should == 'railsapp.local'
  end
end

describe "PassengerApplication, in general" do
  tests PassengerApplication
  
  def after_setup
    @vhost = File.expand_path('../fixtures/blog.vhost.conf', __FILE__)
    @instance_to_be_tested = PassengerApplication.alloc.initWithFile(@vhost)
    
    Kernel.stubs(:system)
  end
  
  it "should parse the correct host & path from a vhost file" do
    passenger_app.host.should == "het-manfreds-blog.local"
    passenger_app.path.should == "/Users/het-manfred/rails code/blog"
  end
  
  it "should set @new_app to false" do
    assigns(:new_app).should.be false
  end
  
  it "should be able to execute shell with administrator permissions" do
    osa = mock('NSAppleScript')
    OSX::NSAppleScript.any_instance.expects(:initWithSource).with('do shell script "/requires/admin/privileges" with administrator privileges').returns(osa)
    osa.expects(:performSelector_withObject).with("executeAndReturnError:", nil)
    
    passenger_app.send(:execute, '/requires/admin/privileges')
  end
  
  it "should return the path to the config file" do
    passenger_app.config_path.should == File.join(SharedPassengerBehaviour::USERS_APACHE_PASSENGER_APPS_DIR, "het-manfreds-blog.local.vhost.conf")
  end
  
  it "should be able to save the config file" do
    passenger_app.expects(:execute).with("/usr/bin/env ruby '#{PassengerApplication::CONFIG_INSTALLER}' '#{passenger_app.config_path}' '/etc/hosts' 'het-manfreds-blog.local' '/Users/het-manfred/rails code/blog'")
    passenger_app.save_config!
  end
  
  it "should mark the application as dirty if a value has changed" do
    passenger_app.stubs(:restart)
    
    assigns(:dirty).should.be false
    passenger_app.setValue_forKey('het-manfreds-blog.local', 'host')
    assigns(:dirty).should.be true
  end
  
  it "should not restart the application if only one of host or path is entered" do
    passenger_app.expects(:restart).times(0)
    
    passenger_app.setValue_forKey('', 'host')
    passenger_app.setValue_forKey('/Users/het-manfred/rails code/blog', 'path')
  end
  
  it "should restart the application if a valid host and path are entered" do
    passenger_app.expects(:restart).times(1)
    passenger_app.setValue_forKey('het-manfreds-blog.local', 'host')
  end
  
  it "should save the config before restarting if it was marked dirty" do
    passenger_app.expects(:save_config!).times(1)
    assigns(:dirty, true)
    passenger_app.restart
  end
  
  it "should not save the config before restarting if it wasn't marked dirty" do
    passenger_app.expects(:save_config!).times(0)
    assigns(:dirty, false)
    passenger_app.restart
  end
  
  it "should restart the application" do
    Kernel.expects(:system).with("/usr/bin/touch '/Users/het-manfred/rails code/blog/tmp/restart.txt'")
    passenger_app.restart
  end
  
  it "should remove an application" do
    passenger_app.expects(:execute).with("/usr/bin/env ruby '#{PassengerApplication::CONFIG_UNINSTALLER}' '#{passenger_app.config_path}' '/etc/hosts' 'het-manfreds-blog.local'")
    passenger_app.remove
  end
end