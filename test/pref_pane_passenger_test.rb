require File.expand_path('../test_helper', __FILE__)
require 'PassengerPref'

def OSX._ignore_ns_override; true; end

class InstallPassengerWarning < OSX::NSView
  def initWithTextField
    if init
      text_field = OSX::NSTextField.alloc.init
      text_field.stringValue = "blabla http://www.modrails.com blabla"
      addSubview text_field
      self
    end
  end
end

describe "PrefPanePassenger, while loading" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init,
               :applicationsTableView => OSX::NSTableView.alloc.init,
               :installPassengerWarning => OSX::InstallPassengerWarning.alloc.initWithTextField,
               :authorizationView => OSX::SFAuthorizationView.alloc.init
    
    pref_pane.stubs(:passenger_installed?).returns(false)
  end
  
  it "should enable the 'install passenger' warning in the UI if the gem can't be found" do
    installPassengerWarning.hidden = true
    pref_pane.mainViewDidLoad
    installPassengerWarning.hidden?.should.be false
  end
  
  it "should add existing applications found in /etc/apache2/users/passenger_apps to the array controller: applicationsController" do
    dir = "/etc/apache2/users/#{OSX.NSUserName}-passenger-apps"
    blog, paste = ["#{dir}/blog.vhost.conf", "#{dir}/paste.vhost.conf"]
    blog_stub, paste_stub = stub("PassengerApplication: blog"), stub("PassengerApplication: paste")
    
    PassengerApplication.any_instance.expects(:initWithFile).with(blog).returns(blog_stub)
    PassengerApplication.any_instance.expects(:initWithFile).with(paste).returns(paste_stub)
    
    pref_pane.stubs(:is_users_apache_config_setup?).returns(true)
    Dir.stubs(:glob).with("#{dir}/*.vhost.conf").returns([blog, paste])
    pref_pane.mainViewDidLoad
    
    applicationsController.content.should == [blog_stub, paste_stub]
  end
  
  it "should configure the authorization view" do
    authorizationView.expects(:string=).with(OSX::KAuthorizationRightExecute)
    pref_pane.mainViewDidLoad
    authorizationView.delegate.should.be pref_pane
  end
end

describe "PrefPanePassenger, in general" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init,
               :authorizationView => OSX::SFAuthorizationView.alloc.init,
               :installPassengerWarning => OSX::InstallPassengerWarning.alloc.initWithTextField
    
    mainView = stub('Main View')
    pref_pane.stubs(:mainView).returns(mainView)
    window = stub('Main Window')
    mainView.stubs(:window).returns(window)
    
    pref_pane.mainViewDidLoad
  end
  
  it "should set authorized to false" do
    assigns(:authorized).should.be false
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
    remove_app.expects(:remove)
    
    applicationsController.content = [remove_app, stay_app]
    applicationsController.selectedObjects = [remove_app]
    
    pref_pane.remove(nil)
    applicationsController.content.should == [stay_app]
  end
  
  it "should open a directory browse panel and use the result as the path for the current selected application" do
    app = PassengerApplication.alloc.initWithPath('/previous/path/to/Blog')
    applicationsController.content = [app]
    applicationsController.selectedObjects = [app]
    
    OSX::NSOpenPanel.any_instance.expects(:canChooseDirectories=).with(true)
    OSX::NSOpenPanel.any_instance.expects(:canChooseFiles=).with(false)
    OSX::NSOpenPanel.any_instance.expects(:objc_send).with(
      :beginSheetForDirectory, app.path,
      :file, nil,
      :types, nil,
      :modalForWindow, pref_pane.mainView.window,
      :modalDelegate, pref_pane,
      :didEndSelector, 'openPanelDidEnd:returnCode:contextInfo:',
      :contextInfo, nil
    )
    pref_pane.browse
    
    panel = stub('NSOpenPanel')
    panel.stubs(:filename).returns('/some/path/to/Blog')
    
    app.expects(:setValue_forKey).with('/some/path/to/Blog', 'path')
    pref_pane.openPanelDidEnd_returnCode_contextInfo(panel, OSX::NSOKButton, nil)
  end
  
  it "should be able to check if the passenger gem is installed" do
    pref_pane.expects(:`).with('/usr/bin/gem list passenger').returns("*** LOCAL GEMS ***\n\npassenger (1.0.5, 1.0.1)\n")
    pref_pane.send(:passenger_installed?).should.be true
    
    pref_pane.expects(:`).with('/usr/bin/gem list passenger').returns("*** LOCAL GEMS ***\n\n\n")
    pref_pane.send(:passenger_installed?).should.be false
  end
  
  it "should forward delegate messages from the authorization view to the security helper" do
    authorization = stub('Authorization Ref')
    authorizationView.authorization.stubs(:authorizationRef).returns(authorization)
    pref_pane.authorizationViewDidAuthorize
    OSX::SecurityHelper.sharedInstance.should.be.authorized
    assigns(:authorized).should.be true
    
    pref_pane.authorizationViewDidDeauthorize
    OSX::SecurityHelper.sharedInstance.should.not.be.authorized
    assigns(:authorized).should.be false
  end
  
  it "should open the browse panel when a new empty application is added to the applications array" do
    pref_pane.expects(:browse).times(1)
    pref_pane.setValue_forKey([PassengerApplication.alloc.init], 'applications')
    
    pref_pane.expects(:browse).times(0)
    pref_pane.setValue_forKey([PassengerApplication.alloc.init, PassengerApplication.alloc.initWithFile(File.expand_path('../fixtures/blog.vhost.conf', __FILE__))], 'applications')
  end
end

describe "PrefPanePassenger, with drag and drop support" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init,
               :applicationsTableView => OSX::NSTableView.alloc.init,
               :installPassengerWarning => OSX::InstallPassengerWarning.alloc.initWithTextField
    
    @tmp = File.expand_path('../tmp')
    FileUtils.mkdir_p @tmp
  end
  
  def after_teardown
    FileUtils.rm_rf @tmp
  end
  
  it "should configure the table view to accept drag and drop operations" do
    pref_pane.mainViewDidLoad
    applicationsTableView.dataSource.should.be pref_pane
    applicationsTableView.registeredDraggedTypes.should == [OSX::NSFilenamesPboardType]
  end
  
  it "should allow multiple directories to be dropped" do
    stub_pb_and_info_with_two_directories
    pref_pane.tableView_validateDrop_proposedRow_proposedDropOperation(nil, @info, nil, nil).should == OSX::NSDragOperationGeneric
  end
  
  it "should not allow files to be dropped" do
    dir = File.join(@tmp, 'dir')
    FileUtils.mkdir_p dir
    file = File.join(@tmp, 'file')
    `touch #{file}`
    stub_pb_and_info_with [file, dir]
    
    pref_pane.tableView_validateDrop_proposedRow_proposedDropOperation(nil, @info, nil, nil).should == OSX::NSDragOperationNone
  end
  
  it "should add an application to the applicationsController for each directory and then start them" do
    stub_pb_and_info_with_two_directories
    
    apps_should_be = lambda do |apps|
      apps.map { |app| app.path } == @dirs and apps.map { |app| app.host } == %w{ app1.local app2.local }
    end
    
    PassengerApplication.expects(:startApplications).with &apps_should_be
    pref_pane.tableView_acceptDrop_row_dropOperation(nil, @info, nil, nil)
    apps_should_be.call(applicationsController.content)
  end
  
  private
  
  def stub_pb_and_info_with_two_directories
    dir1 = File.join(@tmp, 'app1')
    dir2 = File.join(@tmp, 'app2')
    @dirs = [dir1, dir2]
    @dirs.each { |f| FileUtils.mkdir_p f }
    stub_pb_and_info_with @dirs
  end
  
  def stub_pb_and_info_with(files)
    @pb = stub("NSPasteboard")
    @info = stub("NSDraggingInfo")
    @info.stubs(:draggingPasteboard).returns(@pb)
    @pb.stubs(:propertyListForType).with(OSX::NSFilenamesPboardType).returns(files.to_ns)
  end
end