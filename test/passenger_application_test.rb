require File.expand_path('../test_helper', __FILE__)
require 'PassengerApplication'

class Hash
  def except(*keys)
    copy = dup
    keys.each do |key|
      copy.delete(key)
    end
    copy
  end
end

describe "PassengerApplication, with a new application" do
  tests PassengerApplication
  
  def after_setup
    @instance_to_be_tested = PassengerApplication.alloc.init
    passenger_app.stubs(:execute)
  end
  
  it "should initialize with empty path & host" do
    passenger_app.path.should == ''
    passenger_app.host.should == ''
    passenger_app.should.be.new_app
    assigns(:dirty).should.be false
    assigns(:valid).should.be false
  end
  
  it "should not start the application if only one of host or path is entered" do
    passenger_app.expects(:start).times(0)
    
    passenger_app.setValue_forKey('het-manfreds-blog.local', 'host')
    passenger_app.setValue_forKey('', 'host')
    passenger_app.setValue_forKey('/Users/het-manfred/rails code/blog', 'path')
  end
  
  it "should set the default host if a path is entered (probably via browse)" do
    passenger_app.setValue_forKey('/Users/het-manfred/rails code/blog', 'path')
    assigns(:host).should == 'blog.local'
  end
  
  it "should start the application for the first time" do
    passenger_app.expects(:start).times(1)
    passenger_app.apply
  end
  
  it "should start the application by gracefully restarting apache" do
    passenger_app.expects(:save_config!).times(1)
    passenger_app.start
  end
  
  it "should set a default host name if initialized with initWithPath" do
    PassengerApplication.alloc.initWithPath("/some/path/to/RailsApp").host.should == 'railsapp.local'
  end
  
  it "should be valid if a path is set as it will also set the host" do
    passenger_app.setValue_forKey('/Users/het-manfred/rails code/blog', 'path')
    assigns(:valid).should.be true
  end
  
  it "should mark the app as dirty if it's initialized with a path" do
    PassengerApplication.alloc.initWithPath('/Users/het-manfred/rails code/blog').should.be.dirty
  end
end

describe "PassengerApplication, in general" do
  tests PassengerApplication
  
  def after_setup
    @vhost = File.expand_path('../fixtures/blog.vhost.conf', __FILE__)
    @instance_to_be_tested = PassengerApplication.alloc.initWithFile(@vhost)
    
    Kernel.stubs(:system)
  end
  
  it "should set valid to false after opening a file, because the apply button should still be disabled" do
    assigns(:valid).should.be false
  end
  
  it "should parse the correct host & path from a vhost file" do
    passenger_app.host.should == "het-manfreds-blog.local"
    passenger_app.path.should == "/Users/het-manfred/rails code/blog"
    passenger_app.environment.should == PassengerApplication::DEVELOPMENT
    passenger_app.allow_mod_rewrite.should.be false
    
    passenger_app = PassengerApplication.alloc.initWithFile(File.expand_path('../fixtures/wiki.vhost.conf', __FILE__))
    passenger_app.host.should == "het-manfreds-wiki.local"
    passenger_app.path.should == "/Users/het-manfred/rails code/wiki"
    passenger_app.environment.should == PassengerApplication::PRODUCTION
    passenger_app.allow_mod_rewrite.should.be true
  end
  
  it "should set @new_app to false" do
    assigns(:new_app).should.be false
  end
  
  it "should return the path to the config file" do
    passenger_app.config_path.should == File.join(SharedPassengerBehaviour::PASSENGER_APPS_DIR, "het-manfreds-blog.local.vhost.conf")
  end
  
  it "should be able to save the config file" do
    passenger_app.expects(:execute).with('/usr/bin/ruby', PassengerApplication::CONFIG_INSTALLER, [passenger_app.to_hash].to_yaml)
    passenger_app.save_config!
  end
  
  it "should mark the application as dirty if a value has changed" do
    assigns(:dirty).should.be false
    passenger_app.setValue_forKey('het-manfreds-blog.local', 'host')
    assigns(:dirty).should.be true
  end
  
  it "should be valid if both a path and a host are entered" do
    passenger_app.setValue_forKey('', 'host')
    assigns(:valid).should.be false
    passenger_app.setValue_forKey('foo.local', 'host')
    assigns(:valid).should.be true
    passenger_app.setValue_forKey(nil, 'host')
    assigns(:valid).should.be false
    passenger_app.setValue_forKey('foo.local', 'host')
    assigns(:valid).should.be true
    
    passenger_app.setValue_forKey('', 'path')
    assigns(:valid).should.be false
    passenger_app.setValue_forKey('/some/path', 'path')
    assigns(:valid).should.be true
    passenger_app.setValue_forKey(nil, 'path')
    assigns(:valid).should.be false
    passenger_app.setValue_forKey('/some/path', 'path')
    assigns(:valid).should.be true
  end
  
  it "should restart the application for an existing application" do
    passenger_app.expects(:restart).times(1)
    
    passenger_app.setValue_forKey('/some/path', 'path')
    passenger_app.apply
    
    assigns(:dirty).should.be false
    assigns(:valid).should.be false
  end
  
  it "should save the config before restarting if it was marked dirty" do
    passenger_app.expects(:save_config!).times(1)
    assigns(:dirty, true)
    passenger_app.apply
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
  
  it "should remove application(s)" do
    SharedPassengerBehaviour.expects(:execute).with('/usr/bin/ruby', PassengerApplication::CONFIG_UNINSTALLER, [passenger_app.to_hash].to_yaml)
    PassengerApplication.removeApplications([passenger_app].to_ns)
  end
  
  it "should return it's attributes as a hash without NS classes" do
    assigns(:host, 'app.local'.to_ns)
    assigns(:allow_mod_rewrite, false.to_ns)
    passenger_app.to_hash.should == { 'config_path' => passenger_app.config_path, 'host' => 'app.local', 'path' => passenger_app.path, 'environment' => 'development', 'allow_mod_rewrite' => false }
    passenger_app.to_hash.to_yaml.should.not.include 'NSCF'
  end
  
  it "should start multiple applications at once" do
    app1 = PassengerApplication.alloc.initWithPath('/rails/app1'.to_ns)
    app2 = PassengerApplication.alloc.initWithPath('/rails/app2'.to_ns)
    
    SharedPassengerBehaviour.expects(:execute).times(1).with('/usr/bin/ruby', PassengerApplication::CONFIG_INSTALLER, [app1.to_hash, app2.to_hash].to_yaml)
    
    PassengerApplication.startApplications [app1, app2].to_ns
  end
  
  it "should remember all the original values for the case that the user wants to revert" do
    passenger_app.setValue_forKey('foo.local', 'host')
    passenger_app.setValue_forKey('/some/path', 'path')
    passenger_app.setValue_forKey('production', 'environment')
    passenger_app.setValue_forKey(true, 'allow_mod_rewrite')
    
    passenger_app.should.be.dirty
    passenger_app.should.be.valid
    passenger_app.to_hash.except('config_path').should == { 'host' => 'foo.local', 'path' => '/some/path', 'environment' => 'production', 'allow_mod_rewrite' => true }
    
    passenger_app.revert
    
    passenger_app.should.not.be.dirty
    passenger_app.should.not.be.valid
    passenger_app.to_hash.except('config_path').should == { 'host' => 'het-manfreds-blog.local', 'path' => '/Users/het-manfred/rails code/blog', 'environment' => 'development', 'allow_mod_rewrite' => false }
  end
  
  it "should first remove a config and then add it again if the host has changed so we don't leave stale files/hosts" do
    passenger_app.setValue_forKey('foo.local', 'host')
    passenger_app.expects(:execute).with('/usr/bin/ruby', PassengerApplication::CONFIG_UNINSTALLER, [assigns(:original_values)].to_yaml)
    passenger_app.expects(:save_config!)
    passenger_app.apply
  end
end