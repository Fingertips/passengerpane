require File.expand_path('../test_helper', __FILE__)
require 'PassengerPref'

describe "PrefPanePassenger" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init
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
  
  it "should add existing applications found in /etc/apache2/users/passenger_apps to the array controller: applicationsController" do
    dir = "/etc/apache2/users/passenger_apps"
    blog, paste = ["#{dir}/blog.vhost.conf", "#{dir}/paste.vhost.conf"]
    blog_stub, paste_stub = stub("PassengerApplication: blog"), stub("PassengerApplication: paste")
    
    PassengerApplication.any_instance.expects(:initWithFile).with(blog).returns(blog_stub)
    PassengerApplication.any_instance.expects(:initWithFile).with(paste).returns(paste_stub)
    
    Dir.stubs(:glob).with("#{dir}/*.vhost.conf").returns([blog, paste])
    pref_pane.mainViewDidLoad
    
    applicationsController.content.should == [blog_stub, paste_stub]
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