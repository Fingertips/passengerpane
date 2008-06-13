require File.expand_path('../test_helper', __FILE__)
require 'PassengerPref'

def OSX._ignore_ns_override; true; end

describe "PrefPanePassenger, while loading" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init,
               :applicationsTableView => OSX::NSTableView.alloc.init,
               :installPassengerWarning => OSX::NSView.alloc.init
    
    pref_pane.stubs(:passenger_installed?).returns(true)
  end
  
  it "should enable the 'install passenger' warning in the UI if the gem can't be found" do
    installPassengerWarning.hidden = true
    
    pref_pane.stubs(:passenger_installed?).returns(false)
    pref_pane.mainViewDidLoad
    installPassengerWarning.hidden?.should.be false
  end
  
  it "should check if the users apache config is set up" do
    File.expects(:read).with("/etc/apache2/users/#{OSX.NSUserName}.conf").returns("</Directory>")
    pref_pane.send(:is_users_apache_config_setup?).should.be false
    
    File.expects(:read).with("/etc/apache2/users/#{OSX.NSUserName}.conf").returns(%{
      </Directory>
      
      LoadModule passenger_module /Library/Ruby/Gems/1.8/gems/passenger-25.3.1/ext/apache2/mod_passenger.so
      RailsSpawnServer /Library/Ruby/Gems/1.8/gems/passenger-25.3.1/bin/passenger-spawn-server
      RailsRuby /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby
      RailsEnv development
    })
    pref_pane.send(:is_users_apache_config_setup?).should.be true
  end
  
  it "should not check the apache configuration if the gem hasn't been found" do
    pref_pane.stubs(:passenger_installed?).returns(false)
    pref_pane.expects(:is_users_apache_config_setup?).times(0)
    pref_pane.mainViewDidLoad
  end
  
  it "should ask the user if we should set up the passenger apache config for them" do
    OSX::NSAlert.any_instance.expects(:runModal).returns(OSX::NSAlertFirstButtonReturn)
    pref_pane.send(:user_wants_us_to_setup_config?).should.be true
  end
  
  it "should ask the user if we should set up passenger apache config for them before actually doing it" do
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
    pref_pane.send(:setup_users_apache_config!)
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
end

describe "PrefPanePassenger, in general" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init,
               :newApplicationPathTextField => OSX::NSTextField.alloc.init,
               :newApplicationHostTextField => OSX::NSTextField.alloc.init
               
    pref_pane.stubs(:is_users_apache_config_setup?).returns(true)
    pref_pane.stubs(:install_passenger!).returns(true)
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
    remove_app.expects(:remove)
    
    applicationsController.content = [remove_app, stay_app]
    applicationsController.selectedObjects = [remove_app]
    
    pref_pane.remove(nil)
    applicationsController.content.should == [stay_app]
  end
  
  it "should open a directory browse panel and use the result as the path for the current selected application" do
    OSX::NSOpenPanel.any_instance.expects(:canChooseDirectories=).with(true)
    OSX::NSOpenPanel.any_instance.expects(:canChooseFiles=).with(false)
    OSX::NSOpenPanel.any_instance.stubs(:runModal).returns(OSX::NSOKButton)
    OSX::NSOpenPanel.any_instance.stubs(:filenames).returns(['/some/path/to/Blog'])
    
    pref_pane.browse
    newApplicationPathTextField.stringValue.should == '/some/path/to/Blog'
    newApplicationHostTextField.stringValue.should == 'blog.local'
  end
  
  it "should add a new application with the values from the form and close the sheet" do
    newApplicationPathTextField.stringValue = '/some/path/to/Blog'
    newApplicationHostTextField.stringValue = 'blog.local'
    
    PassengerApplication.any_instance.expects(:start)
    pref_pane.expects(:closeNewApplicationSheet)
    
    pref_pane.addApplicationFromSheet
    
    app = applicationsController.content.last
    app.path.should == '/some/path/to/Blog'
    app.host.should == 'blog.local'
  end
  
  it "should be able to check if the passenger gem is installed" do
    pref_pane.expects(:`).with('/usr/bin/gem list passenger').returns("*** LOCAL GEMS ***\n\npassenger (1.0.5, 1.0.1)\n")
    pref_pane.send(:passenger_installed?).should.be true
    
    pref_pane.expects(:`).with('/usr/bin/gem list passenger').returns("*** LOCAL GEMS ***\n\n\n")
    pref_pane.send(:passenger_installed?).should.be false
  end
end

describe "PrefPanePassenger, with drag and drop support" do
  tests PrefPanePassenger
  
  def after_setup
    ib_outlets :applicationsController => OSX::NSArrayController.alloc.init,
               :applicationsTableView => OSX::NSTableView.alloc.init,
               :newApplicationPathTextField => OSX::NSTextField.alloc.init,
               :newApplicationHostTextField => OSX::NSTextField.alloc.init
    
    pref_pane.stubs(:passenger_installed?).returns(true)
    
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
  
  it "should allow 1 directory to be dropped" do
    stub_pb_and_info_with_one_directory
    pref_pane.tableView_validateDrop_proposedRow_proposedDropOperation(nil, @info, nil, nil).should == OSX::NSDragOperationGeneric
  end
  
  it "should not allow multiple directories to be dropped" do
    dir1 = File.join(@tmp, 'dir1')
    dir2 = File.join(@tmp, 'dir2')
    dirs = [dir1, dir2]
    dirs.each { |f| FileUtils.mkdir_p f }
    stub_pb_and_info_with dirs
    
    pref_pane.tableView_validateDrop_proposedRow_proposedDropOperation(nil, @info, nil, nil).should == OSX::NSDragOperationNone
  end
  
  it "should not allow files to be dropped" do
    file = File.join(@tmp, 'file')
    `touch #{file}`
    stub_pb_and_info_with [file]
    
    pref_pane.tableView_validateDrop_proposedRow_proposedDropOperation(nil, @info, nil, nil).should == OSX::NSDragOperationNone
  end
  
  it "should open the newApplicationSheet if a directory is dropped" do
    pref_pane.expects(:add)
    
    stub_pb_and_info_with_one_directory
    pref_pane.tableView_acceptDrop_row_dropOperation(nil, @info, nil, nil)
    
    newApplicationPathTextField.stringValue.should == @dir
    newApplicationHostTextField.stringValue.should == 'someapp.local'
  end
  
  private
  
  def stub_pb_and_info_with_one_directory
    @dir = File.join(@tmp, 'SomeApp')
    FileUtils.mkdir_p @dir
    FileUtils.mkdir_p @dir
    stub_pb_and_info_with [@dir]
  end
  
  def stub_pb_and_info_with(files)
    @pb = stub("NSPasteboard")
    @info = stub("NSDraggingInfo")
    @info.stubs(:draggingPasteboard).returns(@pb)
    @pb.stubs(:propertyListForType).with(OSX::NSFilenamesPboardType).returns(files.to_ns)
  end
end