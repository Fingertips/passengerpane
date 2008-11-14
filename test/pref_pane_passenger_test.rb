require File.expand_path('../test_helper', __FILE__)
require File.expand_path('../../PassengerPref', __FILE__)

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

module PrefPanePassengerSpecsHelper
  def set_apps_controller_content(apps)
    applicationsController.content = apps
    applicationsController.selectedObjects = apps
  end
  
  def stub_app_controller_with_number_of_apps(number)
    apps = Array.new(number) do |i|
      stub("PassengerApplication: #{i}")
    end
    set_apps_controller_content(apps)
    apps
  end
  
  def stub_app_controller_with_a_app
    stub_app_controller_with_number_of_apps(1).first
  end
  
  def alert_stub
    window = stub_everything('Window')
    alert = stub('Alert')
    alert.stubs(:window).returns(window)
    alert
  end
end

describe "PrefPanePassenger, while initializing" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :installPassengerWarning => OSX::InstallPassengerWarning.alloc.initWithTextField,
               :authorizationView => OSX::SFAuthorizationView.alloc.init
    
    pref_pane.stubs(:paneWillBecomeActive)
  end
  
  it "should register itself as the sharedInstance" do
    pref_pane.mainViewDidLoad
    PrefPanePassenger.sharedInstance.should.be.instance_of PrefPanePassenger
  end
  
  it "should configure the authorization view" do
    authorizationView.expects(:string=).with(OSX::KAuthorizationRightExecute)
    pref_pane.mainViewDidLoad
    authorizationView.delegate.should.be pref_pane
    assigns(:authorized).should.be false
  end
  
  it "should initialize an empty array which will hold the list of applications" do
    pref_pane.mainViewDidLoad
    apps = assigns(:applications)
    apps.should.be.instance_of OSX::NSCFArray
    apps.should.be.empty
  end
  
  it "should register itself for notifications for if the System Preferences.app will be activated" do
    OSX::NSNotificationCenter.defaultCenter.expects(:objc_send).with(
      :addObserver, pref_pane,
         :selector, 'paneWillBecomeActive:',
             :name, OSX::NSApplicationWillBecomeActiveNotification,
           :object, nil
    )
    pref_pane.mainViewDidLoad
  end
end

describe "PrefPanePassenger, when about to be (re)displayed" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init,
               :applicationsTableView => OSX::NSTableView.alloc.init,
               :installPassengerWarning => OSX::InstallPassengerWarning.alloc.initWithTextField
    
    pref_pane.stubs(:passenger_installed?).returns(false)
  end
  
  it "should enable the 'install passenger' warning in the UI if the Passenger Apache module isn't loaded" do
    installPassengerWarning.hidden = true
    pref_pane.paneWillBecomeActive
    
    installPassengerWarning.hidden?.should.be false
  end
  
  it "should disable the 'install passenger' warning in the UI if the Passenger Apache module is loaded" do
    pref_pane.stubs(:passenger_installed?).returns(true)
    installPassengerWarning.hidden = false
    pref_pane.paneWillBecomeActive
    
    installPassengerWarning.hidden?.should.be true
  end
  
  it "should add existing applications found in #{PassengerPaneConfig::PASSENGER_APPS_DIR} to the array controller: applicationsController" do
    blog_app, paste_app = add_applications!
    pref_pane.paneWillBecomeActive
    
    applicationsController.content.should == [blog_app, paste_app]
    applicationsController.selectedObjects.should == [paste_app]
  end
  
  it "should reload loaded applications from disk" do
    blog_app, paste_app = add_applications!
    pref_pane.paneWillBecomeActive
    
    blog_app.expects(:reload!)
    paste_app.expects(:reload!)
    pref_pane.willSelect
  end
  
  private
  
  def add_applications!
    dir = PassengerPaneConfig::PASSENGER_APPS_DIR
    ext = PassengerPaneConfig::PASSENGER_APPS_EXTENSION
    blog, paste = ["#{dir}/blog.#{ext}", "#{dir}/paste.#{ext}"]
    apps = stub("PassengerApplication: blog"), stub("PassengerApplication: paste")
    PassengerApplication.stubs(:existingApplications).returns(apps)
    apps
  end
end

describe "PrefPanePassenger, while checking for passenger" do
  tests PrefPanePassenger
  
  it "should return true if the Passenger Apache modules is loaded" do
    pref_pane.stubs(:`).with('/usr/sbin/httpd -t -D DUMP_MODULES 2>&1').returns(%{
[Fri Jun 20 12:20:03 2008] [warn] _default_ VirtualHost overlap on port 80, the first has precedence
[Fri Jun 20 12:20:03 2008] [warn] _default_ VirtualHost overlap on port 80, the first has precedence
Loaded Modules:
 core_module (static)
 mpm_prefork_module (static)
 http_module (static)
 passenger_module (shared)
Syntax OK})
    
    pref_pane.send(:passenger_installed?).should.be true
  end
  
  it "should return false if the Passenger Apache modules is not loaded" do
    pref_pane.stubs(:`).with('/usr/sbin/httpd -t -D DUMP_MODULES 2>&1').returns(%{
[Fri Jun 20 12:20:03 2008] [warn] _default_ VirtualHost overlap on port 80, the first has precedence
[Fri Jun 20 12:20:03 2008] [warn] _default_ VirtualHost overlap on port 80, the first has precedence
Loaded Modules:
 core_module (static)
 mpm_prefork_module (static)
 http_module (static)
Syntax OK})

    pref_pane.send(:passenger_installed?).should.be false
  end
end

describe "PrefPanePassenger, when removing applications" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init
  end
  
  it "should remove the selected applications from the applicationsController" do
    remove_app, stay_app = stub("PassengerApplication: should be removed"), stub("PassengerApplication: should stay")
    remove_app.stubs(:new_app?).returns(false)
    stay_app.stubs(:new_app?).returns(false)
    PassengerApplication.expects(:removeApplications).with([remove_app])
    
    applicationsController.content = [remove_app, stay_app]
    applicationsController.selectedObjects = [remove_app]
    
    pref_pane.remove
    applicationsController.content.should == [stay_app]
  end
  
  it "should not try to delete files when removing a new application" do
    app = PassengerApplication.alloc.init
    applicationsController.content = [app]
    applicationsController.selectedObjects = [app]
    
    PassengerApplication.expects(:removeApplications).times(0)
    pref_pane.remove
    applicationsController.content.should.be.empty
  end
  
  it "should not open the browse panel after removing applications" do
    pref_pane.expects(:browse).times(0)
    pref_pane.setValue_forKey([], 'applications')
  end
end

describe "PrefPanePassenger, when adding applications" do
  tests PrefPanePassenger
  
  it "should open the browse panel when a new empty application is added to the applications array" do
    pref_pane.expects(:browse).times(1)
    pref_pane.setValue_forKey([PassengerApplication.alloc.init], 'applications')
    
    pref_pane.expects(:browse).times(0)
    pref_pane.setValue_forKey([PassengerApplication.alloc.init, PassengerApplication.alloc.initWithFile(File.expand_path('../fixtures/blog.vhost.conf', __FILE__))], 'applications')
  end
end

describe "PrefPanePassenger, when unselecting the pane" do
  tests PrefPanePassenger
  
  include PrefPanePassengerSpecsHelper
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init
    
    mainView = stub('Main View')
    pref_pane.stubs(:mainView).returns(mainView)
    window = stub('Main Window')
    mainView.stubs(:window).returns(window)
    
    pref_pane.stubs(:passenger_installed?).returns(true)
    pref_pane.mainViewDidLoad
  end
  
  it "should show a warning if the current selected application is dirty" do
    set_apps_controller_content [PassengerApplication.alloc.initWithPath('/previous/path/to/Blog')]
    
    OSX::NSAlert.any_instance.expects(:objc_send).with(
      :beginSheetModalForWindow, pref_pane.mainView.window,
      :modalDelegate, pref_pane,
      :didEndSelector, 'unsavedChangesAlertDidEnd:returnCode:contextInfo:',
      :contextInfo, nil
    ).times(1)
    
    pref_pane.shouldUnselect.should == OSX::NSUnselectLater
  end
  
  it "should not show a warning if there are no dirty applications" do
    assigns(:dirty_apps, false)
    OSX::NSAlert.any_instance.expects(:objc_send).times(0)
    pref_pane.shouldUnselect.should == OSX::NSUnselectNow
  end
  
  it "should not show a warning if there aren't any applications" do
    assigns(:dirty_apps, true)
    applicationsController.content = []
    OSX::NSAlert.any_instance.expects(:objc_send).times(0)
    pref_pane.shouldUnselect.should == OSX::NSUnselectNow
  end
  
  it "should save the application and then tell the pane to unselect if the user chooses to apply unsaved changes" do
    pref_pane.expects(:apply)
    pref_pane.expects(:replyToShouldUnselect).with(true)
    pref_pane.unsavedChangesAlertDidEnd_returnCode_contextInfo(alert_stub, PrefPanePassenger::APPLY, nil)
  end
  
  it "should tell the pane to not unselect if the user chooses to review unsaved changes" do
    pref_pane.expects(:apply).times(0)
    pref_pane.expects(:replyToShouldUnselect).with(false)
    pref_pane.unsavedChangesAlertDidEnd_returnCode_contextInfo(alert_stub, PrefPanePassenger::CANCEL, nil)
  end
  
  it "should remove new and unsaved apps and revert unsaved existing apps and tell the pane to unselect if the user chooses to not apply unsaved changes" do
    new_app = PassengerApplication.alloc.init
    existing_app = PassengerApplication.alloc.initWithFile(File.expand_path('../fixtures/blog.vhost.conf', __FILE__))
    existing_app.setValue_forKey('foo.local', 'host')
    
    set_apps_controller_content([new_app, existing_app])
    
    PassengerApplication.expects(:removeApplications).times(0)
    pref_pane.expects(:replyToShouldUnselect).with(true)
    pref_pane.unsavedChangesAlertDidEnd_returnCode_contextInfo(alert_stub, PrefPanePassenger::DONT_APPLY, nil)
    
    applicationsController.content.should == [existing_app]
    applicationsController.content.first.host.should == "het-manfreds-blog.local"
  end
end

describe "PrefPanePassenger, when applying changes" do
  tests PrefPanePassenger
  
  include PrefPanePassengerSpecsHelper
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init
    pref_pane.stubs(:authorize!).returns(true)
  end
  
  it "should show the authorizationView if necessary" do
    pref_pane.expects(:authorize!).returns(true)
    pref_pane.apply
  end
  
  it "should send the apply message to all the dirty applications" do
    apps = stub_app_controller_with_number_of_apps(3)
    
    apps.first.stubs(:dirty?).returns(false)
    apps.first.expects(:apply).times(0)
    
    apps[1..2].each do |app|
      app.stubs(:dirty?).returns(true)
      app.expects(:apply).times(1)
    end
    
    pref_pane.apply
  end
  
  it "should set @dirty_apps and @revertable_apps to false once all unsaved apps received the apply message" do
    assigns(:dirty_apps, true)
    assigns(:revertable_apps, true)
    pref_pane.apply
    pref_pane.dirty_apps.should.be false
    pref_pane.revertable_apps.should.be false
  end
end

describe "PrefPanePassenger, when reverting changes" do
  tests PrefPanePassenger
  
  include PrefPanePassengerSpecsHelper
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init
  end
  
  it "should send the revert message to all revertable applications" do
    apps = stub_app_controller_with_number_of_apps(3)
    
    apps.first.stubs(:revertable?).returns(false)
    apps.first.expects(:revert).times(0)
    
    apps[1..2].each do |app|
      app.stubs(:revertable?).returns(true)
      app.expects(:revert).times(1)
    end
    
    pref_pane.revert
  end
  
  it "should set @dirty_apps and @revertable_apps to false once all unsaved apps received the revert message" do
    assigns(:dirty_apps, true)
    assigns(:revertable_apps, true)
    pref_pane.revert
    pref_pane.dirty_apps.should.be false
    pref_pane.revertable_apps.should.be false
  end
end

describe "PrefPanePassenger, when restarting applications" do
  tests PrefPanePassenger
  
  include PrefPanePassengerSpecsHelper
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init
  end
  
  it "should send the restart message to all not new applications" do
    apps = stub_app_controller_with_number_of_apps(3)
    
    apps.first.stubs(:new_app?).returns(true)
    apps.first.expects(:restart).times(0)
    
    apps[1..2].each do |app|
      app.stubs(:new_app?).returns(false)
      app.expects(:restart).times(1)
    end
    
    pref_pane.restart
  end
end

describe "PrefPanePassenger, when using the directory browse panel" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init
    
    mainView = stub('Main View')
    pref_pane.stubs(:mainView).returns(mainView)
    window = stub('Main Window')
    mainView.stubs(:window).returns(window)
    
    PrefPanePassenger.any_instance.stubs(:applicationMarkedDirty)
  end
  
  it "should display the path to the currently selected application" do
    app = PassengerApplication.alloc.initWithPath('/previous/path/to/Blog')
    applicationsController.content = [app]
    applicationsController.selectedObjects = [app]
    
    pref_pane.send(:path_for_browser).should == '/previous/path/to/Blog'
  end
  
  it "should display the home directory if no application is selected" do
    applicationsController.selectedObjects = []
    pref_pane.send(:path_for_browser).to_s.should == File.expand_path('~')
  end
  
  it "should set the path to the selected directory as the path for the currently selected application" do
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
  
  it "should remove the new application if the user pressed cancel in the browse panel if it's a new not dirty app" do
    remove_app = PassengerApplication.alloc.init
    
    applicationsController.content = [remove_app]
    applicationsController.selectedObjects = [remove_app]
    
    pref_pane.openPanelDidEnd_returnCode_contextInfo(nil, OSX::NSCancelButton, nil)
    applicationsController.content.should.be.empty
  end
  
  it "should not remove an application when the user presses cancel in the browse panel if the app is dirty" do
    stay_app = PassengerApplication.alloc.init
    stay_app.setValue_forKey('foo.local', 'host')
    
    applicationsController.content = [stay_app]
    applicationsController.selectedObjects = [stay_app]
    
    pref_pane.openPanelDidEnd_returnCode_contextInfo(nil, OSX::NSCancelButton, nil)
    applicationsController.content.should == [stay_app]
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
    
    pref_pane.stubs(:passenger_installed?).returns(true)
    PassengerApplication.stubs(:existingApplications).returns([])
    pref_pane.mainViewDidLoad
  end
  
  def after_teardown
    FileUtils.rm_rf @tmp
  end
  
  it "should configure the table view to accept drag and drop operations" do
    applicationsTableView.dataSource.should.be pref_pane
    applicationsTableView.registeredDraggedTypes.should == [OSX::NSFilenamesPboardType]
  end
  
  it "should allow multiple directories to be dropped and always add to the bottom of the list" do
    assigns(:authorized, true)
    stub_pb_and_info_with_two_directories
    
    applicationsTableView.expects(:setDropRow_dropOperation).with(0, OSX::NSTableViewDropAbove)
    
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
  
  it "should add valid applications to the applicationsController" do
    stub_pb_and_info_with_two_directories
    
    PassengerApplication.expects(:startApplications).times(0)
    pref_pane.tableView_acceptDrop_row_dropOperation(nil, @info, nil, nil)
    
    apps = applicationsController.content
    apps.map { |app| app.path }.should == @dirs
    apps.map { |app| app.host }.should == %w{ app1.local app2.local }
    apps.all? { |app| app.valid? }.should.be true
  end
  
  it "should not allow directories to be dropped if not authorized" do
    assigns(:authorized, false)
    pref_pane.tableView_validateDrop_proposedRow_proposedDropOperation(nil, nil, nil, nil).should == OSX::NSDragOperationNone
  end
  
  it "should not open the browse panel if directories are dropped" do
    assigns(:dropping_directories, false)
    stub_pb_and_info_with_two_directories
    
    applicationsController.expects(:addObjects).with do |apps|
      pref_pane.setValue_forKey([PassengerApplication.alloc.init], 'applications')
      true
    end
    
    pref_pane.expects(:browse).times(0)
    pref_pane.tableView_acceptDrop_row_dropOperation(nil, @info, nil, nil)
    assigns(:dropping_directories).should.be false
  end
  
  it "should allow entries from the table view to be dragged to for instance a text editor" do
    app1 = PassengerApplication.alloc.init
    app2 = PassengerApplication.alloc.init
    app1.host = "app1.local"
    app2.host = "app2.local"
    
    applicationsController.content = [app1, app2]
    applicationsController.selectedObjects = [app1, app2]
    
    pboard = OSX::NSPasteboard.generalPasteboard
    allowed = pref_pane.tableView_writeRowsWithIndexes_toPasteboard(nil, OSX::NSIndexSet.indexSetWithIndexesInRange(0..1), pboard)
    allowed.should.be true
    pboard.propertyListForType(OSX::NSFilenamesPboardType).should == [app1.config_path, app2.config_path]
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

describe "PrefPanePassenger, in general" do
  tests PrefPanePassenger
  
  include PrefPanePassengerSpecsHelper
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init,
               :authorizationView => OSX::SFAuthorizationView.alloc.init
    
    pref_pane.stubs(:passenger_installed?).returns(true)
    pref_pane.mainViewDidLoad
  end
  
  it "should change the authorized state if a authorization request succeeds" do
    authorizationView.authorization.expects(:objc_send).with(
      :permitWithRight, OSX::KAuthorizationRightExecute,
      :flags, (OSX::KAuthorizationFlagPreAuthorize | OSX::KAuthorizationFlagExtendRights | OSX::KAuthorizationFlagInteractionAllowed)
    ).returns(0)
    
    pref_pane.expects(:authorizationViewDidAuthorize).times(1)
    pref_pane.send(:authorize!).should.be true
  end
  
  it "should not change the authorized state if a authorization request fails" do
    authorizationView.authorization.expects(:objc_send).with(
      :permitWithRight, OSX::KAuthorizationRightExecute,
      :flags, (OSX::KAuthorizationFlagPreAuthorize | OSX::KAuthorizationFlagExtendRights | OSX::KAuthorizationFlagInteractionAllowed)
    ).returns(60007)
    
    pref_pane.expects(:authorizationViewDidAuthorize).times(0)
    pref_pane.send(:authorize!).should.be false
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
  
  it "should know if there are dirty apps" do
    app = PassengerApplication.alloc.init
    set_apps_controller_content([app])
    
    app.setValue_forKey('foo.local', 'host')
    pref_pane.dirty_apps.should.be true
  end
end