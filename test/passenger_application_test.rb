require File.expand_path('../test_helper', __FILE__)
require File.expand_path('../../PassengerApplication', __FILE__)
require File.expand_path('../../PassengerPref.rb', __FILE__)

class Hash
  def except(*keys)
    copy = dup
    keys.each do |key|
      copy.delete(key)
    end
    copy
  end
end

PrefPanePassenger.sharedInstance = PrefPanePassenger.new

describe "PassengerApplication, with a new application" do
  tests PassengerApplication
  
  def after_setup
    PrefPanePassenger.any_instance.stubs(:applicationMarkedDirty)
    passenger_app.stubs(:execute)
  end
  
  it "should initialize with empty path & host" do
    passenger_app.path.should == ''
    passenger_app.host.should == ''
    passenger_app.vhostname.should == '*:80'
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
  
  it "should set the default host if a path is entered (probably via browse) and replace underscores with hyphens" do
    passenger_app.setValue_forKey('/Users/het-manfred/rails code/my_supercool_blog', 'path')
    assigns(:host).should == 'my-supercool-blog.local'
  end
  
  it "should set a default host if initialized with initWithPath" do
    app = PassengerApplication.alloc.initWithPath("/some/path/to/RailsApp")
    app.host.should == 'railsapp.local'
    app.should.be.valid
  end
  
  it "should start the application for the first time" do
    assigns(:valid, true)
    passenger_app.expects(:start).times(1)
    passenger_app.apply
  end
  
  it "should start the application by gracefully restarting apache" do
    passenger_app.expects(:save_config!).times(1)
    passenger_app.start
  end
  
  it "should be valid if a path is set as it will also set the host" do
    passenger_app.setValue_forKey('/Users/het-manfred/rails code/blog', 'path')
    assigns(:valid).should.be true
  end
  
  it "should mark the app as dirty if it's initialized with a path" do
    PassengerApplication.alloc.initWithPath('/Users/het-manfred/rails code/blog').should.be.dirty
  end
  
  it "should return a hash with a default user_defined_data variable that contains the permissions directive and also set it as the value for @user_defined_data" do
    passenger_app.setValue_forKey('/some/path/to/rails/app', 'path')
    
    string = %{
  <directory "/some/path/to/rails/app/public">
    Order allow,deny
    Allow from all
  </directory>}.sub(/^\n/, '')
    
    passenger_app.to_hash['user_defined_data'].should == string
    assigns(:user_defined_data).should == string
  end
  
  it "should not try to reload if it gets the reload message" do
    passenger_app.expects(:load_data_from_vhost_file).times(0)
    passenger_app.should.be.new_app
    passenger_app.should.not.be.valid
    passenger_app.should.not.be.dirty
    passenger_app.should.not.be.revertable
    
    passenger_app.reload!
  end
end

describe "PassengerApplication#application_type" do
  before do
    @vhost = File.expand_path('../fixtures/blog.vhost.conf', __FILE__)
    @passenger_app = PassengerApplication.alloc.initWithFile(@vhost)
  end
  
  it "should recognize it as a Rails application if there's a config/environment.rb file, which contains `Rails::Initializer'" do
    File.stubs(:exist?).with('/Users/het-manfred/rails code/blog/config/environment.rb').returns(true)
    File.stubs(:read).with('/Users/het-manfred/rails code/blog/config/environment.rb').returns("Rails::Initializer.run do |config|\nend")
    @passenger_app.application_type.should == PassengerApplication::RAILS
  end
  
  it "should recognize it as a Rack application if there's a config/environment.rb file, but doesn't contain the string `Rails::Initializer'" do
    File.stubs(:exist?).with('/Users/het-manfred/rails code/blog/config/environment.rb').returns(true)
    File.stubs(:read).with('/Users/het-manfred/rails code/blog/config/environment.rb').returns("Foo bar")
    @passenger_app.application_type.should == PassengerApplication::RACK
  end
  
  it "should recognize it as a Rack application if there's no config/environment.rb file" do
    File.stubs(:exist?).with('/Users/het-manfred/rails code/blog/config/environment.rb').returns(false)
    @passenger_app.application_type.should == PassengerApplication::RACK
  end
end

describe "PassengerApplication, in general" do
  tests PassengerApplication
  
  def after_setup
    PassengerApplication.any_instance.stubs(:application_type).returns(PassengerApplication::RAILS)
    
    @vhost = File.expand_path('../fixtures/blog.vhost.conf', __FILE__)
    @instance_to_be_tested = PassengerApplication.alloc.initWithFile(@vhost)
    
    @tmp_dir = File.join(passenger_app.path, 'tmp')
    File.stubs(:exist?).with(@tmp_dir).returns(true)
    
    PrefPanePassenger.any_instance.stubs(:applicationMarkedDirty)
    Kernel.stubs(:system)
  end
  
  it "should set valid to false after opening a file, because the apply button should still be disabled" do
    assigns(:valid).should.be false
  end
  
  it "should parse the correct host & path from a vhost file" do
    passenger_app.host.should == "het-manfreds-blog.local"
    passenger_app.aliases.should == "manfred-s-blog.local my-blog.local"
    passenger_app.path.should == "/Users/het-manfred/rails code/blog"
    passenger_app.environment.should == PassengerApplication::DEVELOPMENT
    passenger_app.vhostname.should == '*:80'
    
    passenger_app = PassengerApplication.alloc.initWithFile(File.expand_path('../fixtures/wiki.vhost.conf', __FILE__))
    passenger_app.host.should == "het-manfreds-wiki.local"
    passenger_app.aliases.should == ""
    passenger_app.path.should == "/Users/het-manfred/rails code/wiki"
    passenger_app.environment.should == PassengerApplication::PRODUCTION
    passenger_app.vhostname.should == 'het-manfreds-wiki.local:443'
    passenger_app.user_defined_data.should == %{
  BindAddress 192.168.0.123
  <Location "/">
      AuthType Basic
      AuthName "Development Preview"
      AuthUserFile /home2/cogat/htpasswd
      Require valid-user
  </Location>}.sub(/^\n/, '')
  end
  
  it "should parse the correct environment from a Rack app vhost file" do
    passenger_app = PassengerApplication.alloc.initWithFile(File.expand_path('../fixtures/franky.vhost.conf', __FILE__))
    passenger_app.environment.should == PassengerApplication::PRODUCTION
  end
  
  it "should set @new_app to false" do
    assigns(:new_app).should.be false
  end
  
  it "should return the path to the config file" do
    passenger_app.config_path.should == File.join(PassengerPaneConfig::PASSENGER_APPS_DIR, "het-manfreds-blog.local.#{PassengerPaneConfig::PASSENGER_APPS_EXTENSION}")
  end
  
  it "should be able to save the config file" do
    passenger_app.expects(:execute).with('/usr/bin/ruby', PassengerApplication::CONFIG_INSTALLER, [passenger_app.to_hash].to_yaml)
    passenger_app.save_config!
  end
  
  it "should mark the application as dirty if a value has changed" do
    assigns(:dirty).should.be false
    passenger_app.setValue_forKey('het-manfreds-blog.local', 'host')
    assigns(:dirty).should.be true
    
    assigns(:dirty, false)
    passenger_app.setValue_forKey('alias.local', 'aliases')
    assigns(:dirty).should.be true
  end
  
  it "should let the PrefPanePassenger instance know that an app has been marked dirty" do
    PrefPanePassenger.sharedInstance.expects(:applicationMarkedDirty).with(passenger_app)
    passenger_app.setValue_forKey('het-manfreds-blog.local', 'host')
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
  
  it "should not apply if the applications configuration is not valid" do
    passenger_app.setValue_forKey('', 'host')
    passenger_app.expects(:restart).times(0)
    passenger_app.apply
    assigns(:valid).should.be false
    assigns(:dirty).should.be true
  end
  
  it "should create a tmp directory in the source root of the application before restarting if none exists" do
    File.stubs(:exist?).with(@tmp_dir).returns(false)
    
    FileUtils.expects(:mkdir).with(@tmp_dir)
    passenger_app.restart
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
    assigns(:valid, true)
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
    PassengerApplication.expects(:execute).with('/usr/bin/ruby', PassengerApplication::CONFIG_UNINSTALLER, [passenger_app.to_hash].to_yaml)
    PassengerApplication.removeApplications([passenger_app].to_ns)
  end
  
  it "should return it's attributes as a hash without NS classes" do
    assigns(:host, 'app.local'.to_ns)
    assigns(:aliases, 'alias1.local alias2.local'.to_ns)
    assigns(:user_defined_data, "<directory \"/some/path\">\n  foo bar\n</directory>")
    assigns(:vhostname, 'het-manfreds-wiki.local:443')
    
    passenger_app.to_hash.should == {
      'app_type' => 'rails',
      'config_path' => passenger_app.config_path,
      'host' => 'app.local',
      'aliases' => 'alias1.local alias2.local',
      'path' => passenger_app.path,
      'environment' => 'development',
      'vhostname' => 'het-manfreds-wiki.local:443',
      'user_defined_data' => "<directory \"/some/path\">\n  foo bar\n</directory>"
    }
    
    passenger_app.to_hash.to_yaml.should.not.include 'NSCF'
  end
  
  it "should load existing applications" do
    dir = PassengerPaneConfig::PASSENGER_APPS_DIR
    ext = PassengerPaneConfig::PASSENGER_APPS_EXTENSION
    blog, paste = ["#{dir}/blog.#{ext}", "#{dir}/paste.#{ext}"]
    blog_app, paste_app = stub("PassengerApplication: blog"), stub("PassengerApplication: paste")
    
    Dir.stubs(:glob).with("#{dir}/*.#{ext}").returns([blog, paste])
    PassengerApplication.any_instance.stubs(:initWithFile).with(blog).returns(blog_app)
    PassengerApplication.any_instance.stubs(:initWithFile).with(paste).returns(paste_app)
    
    PassengerApplication.existingApplications.should == [blog_app, paste_app]
  end
  
  it "should start multiple applications at once" do
    app1 = PassengerApplication.alloc.initWithPath('/rails/app1'.to_ns)
    app2 = PassengerApplication.alloc.initWithPath('/rails/app2'.to_ns)
    [app1, app2].each { |app| app.instance_variable_set(:@valid, true) }
    
    PassengerApplication.expects(:execute).times(1).with('/usr/bin/ruby', PassengerApplication::CONFIG_INSTALLER, [app1.to_hash, app2.to_hash].to_yaml)
    
    PassengerApplication.startApplications [app1, app2].to_ns
    
    app1.should.not.be.new_app
    app1.should.not.be.valid
    app1.should.not.be.dirty
    app1.should.not.be.revertable
    app2.should.not.be.new_app
    app2.should.not.be.valid
    app2.should.not.be.dirty
    app2.should.not.be.revertable
  end
  
  it "should remember all the original values for the case that the user wants to revert" do
    passenger_app.setValue_forKey('foo.local', 'host')
    passenger_app.setValue_forKey('', 'aliases')
    passenger_app.setValue_forKey('/some/path', 'path')
    passenger_app.setValue_forKey('production', 'environment')
    
    passenger_app.should.be.dirty
    passenger_app.should.be.valid
    passenger_app.to_hash.except('app_type', 'config_path', 'user_defined_data', 'new_app', 'vhostname').should == {
      'host' => 'foo.local',
      'path' => '/some/path',
      'aliases' => '',
      'environment' => 'production'
    }
    
    passenger_app.should.be.revertable
    passenger_app.revert
    passenger_app.should.not.be.revertable
    
    passenger_app.to_hash.except('app_type', 'config_path', 'user_defined_data', 'new_app', 'vhostname').should == {
      'host' => 'het-manfreds-blog.local',
      'aliases' => 'manfred-s-blog.local my-blog.local',
      'path' => '/Users/het-manfred/rails code/blog',
      'environment' => 'development'
    }
  end
  
  it "should first remove a config and then add it again if the host has changed so we don't leave stale files/hosts" do
    passenger_app.setValue_forKey('foo.local', 'host')
    passenger_app.expects(:execute).with('/usr/bin/ruby', PassengerApplication::CONFIG_UNINSTALLER, [assigns(:original_values)].to_yaml)
    passenger_app.expects(:save_config!)
    passenger_app.apply
  end
  
  it "should first remove a config and then add it again if the aliases have changed so we don't leave stale files/hosts" do
    passenger_app.setValue_forKey('alias.local', 'aliases')
    passenger_app.expects(:execute).with('/usr/bin/ruby', PassengerApplication::CONFIG_UNINSTALLER, [assigns(:original_values)].to_yaml)
    passenger_app.expects(:save_config!)
    passenger_app.apply
  end
  
  it "should reload an application from disk and mark it dirty if values have changed, but don't make it revertable" do
    data = File.read(@vhost).sub('development', 'production')
    File.stubs(:read).with(@vhost).returns(data)
    passenger_app.stubs(:config_path).returns(@vhost)
    
    passenger_app.reload!
    passenger_app.environment.should.be PassengerApplication::PRODUCTION
    passenger_app.should.be.dirty
    passenger_app.should.not.be.revertable
  end
  
  it "should reload an application from disk but don't mark it dirty if no values were changed" do
    data = File.read(@vhost)
    File.stubs(:read).with(@vhost).returns(data)
    passenger_app.stubs(:config_path).returns(@vhost)
    
    passenger_app.reload!
    passenger_app.should.not.be.dirty
    passenger_app.should.not.be.revertable
    
    assigns(:original_values)['user_defined_data'] = nil
    passenger_app.reload!
    passenger_app.should.not.be.dirty
    passenger_app.should.not.be.revertable
    
    assigns(:original_values)['user_defined_data'] = ''
    passenger_app.reload!
    passenger_app.should.not.be.dirty
    passenger_app.should.not.be.revertable
    
    assigns(:original_values)['aliases'] = nil
    passenger_app.reload!
    passenger_app.should.not.be.dirty
    passenger_app.should.not.be.revertable
    
    assigns(:original_values)['aliases'] = ''
    passenger_app.reload!
    passenger_app.should.not.be.dirty
    passenger_app.should.not.be.revertable
  end
end

describe "PassengerApplication, when dealing with custom environments" do
  tests PassengerApplication
  
  def after_setup
    PassengerApplication.any_instance.stubs(:application_type).returns(PassengerApplication::RAILS)
    
    @vhost = File.expand_path('../fixtures/staging.vhost.conf', __FILE__)
    @instance_to_be_tested = PassengerApplication.alloc.initWithFile(@vhost)
    
    @tmp_dir = File.join(passenger_app.path, 'tmp')
    File.stubs(:exist?).with(@tmp_dir).returns(true)
    
    passenger_app.stubs(:execute)
    PrefPanePassenger.any_instance.stubs(:applicationMarkedDirty)
    Kernel.stubs(:system)
  end
  
  it "should set the environment variable that the UI is bound to to nil, so that there's no selection" do
    passenger_app.environment.should.be nil
  end
  
  it "should not leave any custom environment declaration in the user defined data" do
    passenger_app.user_defined_data.should.not.include 'RailsEnv staging'    
  end
  
  it "should have stored the custom environment name and added to the original_values" do
    assigns(:custom_environment).should == 'staging'
    assigns(:original_values)['environment'].should == 'staging'
  end
  
  it "should return the custom environment in it's hash representation" do
    passenger_app.to_hash['environment'].should == 'staging'
  end
  
  it "should return the new environment setting if the user has selected one of production|development" do
    passenger_app.setValue_forKey(PassengerApplication::PRODUCTION, 'environment')
    passenger_app.to_hash['environment'].should == 'production'
    assigns(:custom_environment).should.be nil
  end
  
  it "should reset the original_values after saving an application where the user has switched from a custom env to production|development" do
    passenger_app.setValue_forKey(PassengerApplication::PRODUCTION, 'environment')
    passenger_app.apply
    assigns(:original_values)['environment'].should == PassengerApplication::PRODUCTION
  end
end