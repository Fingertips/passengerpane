require File.expand_path('../test_helper', __FILE__)
require 'PassengerPref'

def OSX._ignore_ns_override; true; end

describe "PrefPanePassenger, while loading" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init
  end
  
  it "should add existing applications found in /etc/apache2/users/passenger_apps to the array controller: applicationsController" do
    dir = "/etc/apache2/users/passenger_apps"
    blog, paste = ["#{dir}/blog.vhost.conf", "#{dir}/paste.vhost.conf"]
    blog_stub, paste_stub = stub("PassengerApplication: blog"), stub("PassengerApplication: paste")
    
    PassengerApplication.any_instance.expects(:initWithFile).with(blog).returns(blog_stub)
    PassengerApplication.any_instance.expects(:initWithFile).with(paste).returns(paste_stub)
    
    pref_pane.stubs(:is_users_apache_config_setup?).returns(true)
    Dir.stubs(:glob).with("#{dir}/*.vhost.conf").returns([blog, paste])
    pref_pane.mainViewDidLoad
    
    applicationsController.content.should == [blog_stub, paste_stub]
  end
  
  it "should check if the users apache config is set up" do
    File.expects(:read).with("/etc/apache2/users/#{OSX.NSUserName}.conf").returns("</Directory>")
    pref_pane.is_users_apache_config_setup?.should.be false
    
    File.expects(:read).with("/etc/apache2/users/#{OSX.NSUserName}.conf").returns(%{
      </Directory>
      
      LoadModule passenger_module /Library/Ruby/Gems/1.8/gems/passenger-1.0.1/ext/apache2/mod_passenger.so
      RailsSpawnServer /Library/Ruby/Gems/1.8/gems/passenger-1.0.1/bin/passenger-spawn-server
      RailsRuby /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby
      RailsEnv development
    })
    pref_pane.is_users_apache_config_setup?.should.be true
  end
  
  it "should ask the user if we should set up passenger for them" do
    OSX::NSAlert.any_instance.expects(:runModal).returns(OSX::NSAlertFirstButtonReturn)
    pref_pane.user_wants_us_to_setup_config?.should.be true
  end
  
  it "should ask the user if we should set up passenger for them before actually doing it" do
    pref_pane.stubs(:is_users_apache_config_setup?).returns(false)
    
    pref_pane.stubs(:user_wants_us_to_setup_config?).returns(true)
    pref_pane.expects(:setup_users_apache_config!).times(1)
    pref_pane.mainViewDidLoad
    
    pref_pane.stubs(:user_wants_us_to_setup_config?).returns(false)
    pref_pane.expects(:setup_users_apache_config!).times(0)
    pref_pane.mainViewDidLoad
  end
  
  it "should add the required lines to setup passenger to the users apache config" do
    pref_pane.expects(:execute).with("/usr/bin/env ruby '#{PrefPanePassenger::PASSENGER_CONFIG_INSTALLER}' '#{PrefPanePassenger::USERS_APACHE_CONFIG}'")
    pref_pane.setup_users_apache_config!
  end
end

describe "PrefPanePassenger, in general" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init
    pref_pane.stubs(:is_users_apache_config_setup?).returns(true)
    pref_pane.mainViewDidLoad
  end
  
  it "should initialize an empty array which will hold the list of applications" do
    apps = assigns(:applications)
    apps.should.be.instance_of OSX::NSCFArray
    apps.should.be.empty
  end
  
  it "should setup kvc accessors for the list of applications" do
    assigns(:applications).push "foo"
    pref_pane.valueForKey('applications').should == ['foo'].to_ns
  end
  
  it "should remove the applications that are selected in the applicationsController (which resembles the table view in the ui)" do
    remove_app, stay_app = stub("PassengerApplication: should be removed"), stub("PassengerApplication: should stay")
    remove_app.expects(:remove!)
    
    applicationsController.content = [remove_app, stay_app]
    applicationsController.selectedObjects = [remove_app]
    
    pref_pane.remove(nil)
    applicationsController.content.should == [stay_app]
  end
end