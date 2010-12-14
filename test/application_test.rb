require File.expand_path('../test_helper', __FILE__)

describe "Application" do
  before do
    @configuration = PassengerPane::Configuration.new
  end
  
  it "returns a glob to find all vhosts" do
    PassengerPane::Application.glob(@configuration).should == "/private/etc/apache2/passenger_pane_vhosts/*.vhost.conf"
  end
end

describe "Application, during initialization" do
  before do
    @configuration = PassengerPane::Configuration.new
    @path          = '/Users/jerry/Sites/uploader'
  end
  
  it "accepts additional attributes" do
    host = 'uploader.facebook.local'
    app = PassengerPane::Application.new(@configuration, :host => host, :path => @path)
    app.host.should == host
    app.config_filename.should.end_with("#{host}.#{@configuration.passenger_vhosts_ext}")
  end
end

describe "Application, working on an existing installation" do
  before do
    use_fake_apache_directory
    @configuration = PassengerPane::Configuration.new(fake_apache_directory)
  end
  
  it "returns all applications" do
    apps = PassengerPane::Application.all(@configuration)
    apps.map { |a| a.host }.sort.should == %w(franky.local het-manfreds-blog.local het-manfreds-wiki.local staging.blog.local)
  end
  
  it "does not screw up vhost configurations read from disk" do
    apps = PassengerPane::Application.all(@configuration)
    apps.each do |app|
      added, removed = _diff(File.read(app.config_filename), app.vhost_snippet)
      message = "\nExpected configuration to stay the same but we added:\n#{added.join("\n")}"
      added.should.messaging(message).be.empty
      message = "\nExpected configuration to stay the same but we removed:\n#{removed.join("\n")}"
      added.should.messaging(message).be.empty
    end
  end
  
  it "finds an application by host" do
    app = PassengerPane::Application.find(@configuration, :host => 'staging.blog.local')
    app.host.should == 'staging.blog.local'
  end
  
  it "does not find unknown applications by host" do
    PassengerPane::Application.find(@configuration, :host => 'unknown').should.be.nil
  end
  
  private
  
  def _diff(left, right)
    left_normalized  = _normalize(left)
    right_normalized = _normalize(right)
    
    added   = right_normalized - left_normalized
    removed = left_normalized - right_normalized
    
    [added, removed]
  end
  
  def _normalize(configuration)
    configuration.strip.split("\n").map do |line|
      line.strip
    end
  end
end

describe "A freshly added Application" do
  before do
    use_fake_apache_directory
    @configuration = PassengerPane::Configuration.new(fake_apache_directory)
    @path          = '/Users/jerry/Sites/uploader'
    @application   = PassengerPane::Application.new(@configuration, :path => @path)
  end
  
  it "is new" do
    @application.should.be.new
  end
  
  it "derives the settings associated with the path" do
    @application.host.should == 'uploader.local'
    @application.aliases.should == ''
    @application.path.should == @path
    @application.framework.should == 'rack'
    @application.environment.should  == 'development'
    @application.vhost_address.should == '*:80'
    @application.config_filename.should == File.join(@configuration.apache_directory, 'passenger_pane_vhosts/uploader.local.vhost.conf')
  end
  
  it "converts its attributes to a virtual host configuration snippet" do
    @application.vhost_snippet.should == %{<VirtualHost *:80>
  ServerName uploader.local
  DocumentRoot "/Users/jerry/Sites/uploader/public"
  RackEnv development
  <Directory "/Users/jerry/Sites/uploader/public">
    Order allow,deny
    Allow from all
  </Directory>
</VirtualHost>}
  end
  
  it "knows if the application was changed" do
    @application.should.not.be.changed
    @application.host = 'uploader.facebook.local'
    @application.should.be.changed
    @application.host = 'uploader.local'
    @application.should.not.be.changed
  end
  
  it "knows which hosts were added" do
    added = []
    @application.added_hosts.should == added
    
    @application.host = 'uploader.facebook.local'
    added << @application.host
    
    @application.added_hosts.should == added
    
    @application.aliases = 'assets0.local assets1.local'
    added += @application.aliases.split
    
    @application.added_hosts.should == added
  end
  
  it "knows which hosts were removed" do
    removed = []
    @application.removed_hosts.should == removed
    
    removed << @application.host
    @application.host = 'uploader.facebook.local'
    
    @application.removed_hosts.should == removed
    
    @application.aliases = 'assets0.local assets1.local'
    
    @application.removed_hosts.should == removed
  end
  
  it "registers all configured hosts" do
    PassengerPane::DirectoryServices.expects(:register).with(@application.to_hash['hosts']).returns(true)
    @application.register.should == true
  end
  
  it "unregisters all configured hosts" do
    PassengerPane::DirectoryServices.expects(:unregister).with(@application.to_hash['hosts']).returns(true)
    @application.unregister.should == true
  end
  
  it "syncs the host registration after an application was changed" do
    @application.host = 'uploader.facebook.local'
    @application.expects(:register).returns(true)
    @application.sync_host_registration.should == true
  end
  
  it "saves all changed information to a vhost file and syncs the host registration" do
    @application.expects(:write).returns(true)
    @application.expects(:sync_host_registration).returns(true)
    @application.save.should == true
  end
  
  it "does not sync the host registration when writing the vhost failes during a save" do
    @application.expects(:write).returns(false)
    @application.expects(:sync_host_registration).never
    @application.save.should == false
  end
  
  it "writes its configuration file" do
    File.should.not.exist(@application.config_filename)
    @application.write
    File.should.exist(@application.config_filename)
  end
end

describe "An existing Application" do
  before do
    use_fake_apache_directory
    @configuration = PassengerPane::Configuration.new(fake_apache_directory)
    @application   = @configuration.applications.sort_by { |a| a.host}.first
  end
  
  it "is not new" do
    @application.should.not.be.new
  end
  
  it "parses its attributes from the virtualhost configuration" do
    @application.host.should == 'franky.local'
    @application.aliases.should == ''
    @application.path.should == '/Users/staging/sinatra-apps/franky'
    @application.environment.should  == 'production'
    @application.vhost_address.should == '*:80'
    @application.config_filename.should == File.join(fake_apache_directory, 'passenger_pane_vhosts/franky.vhost.conf')
    @application.framework.should == 'rack'
  end
  
  it "returns its attributes as a hash" do
    by_string = lambda { |k| k.to_s }
    @application.to_hash.keys.sort_by(&by_string).should == ['hosts', *PassengerPane::Application::ATTRIBUTES.map { |a| a.to_s }].sort_by(&by_string)
  end
  
  it "syncs the host registration after an application was changed" do
    @application.host = 'franky.facebook.local'
    PassengerPane::DirectoryServices.expects(:register).with(@application.added_hosts).returns(true)
    PassengerPane::DirectoryServices.expects(:unregister).with(@application.removed_hosts).returns(true)
    @application.sync_host_registration.should == true
  end
  
  it "saves all changed information to a vhost file and syncs the host registration" do
    @application.expects(:write).returns(true)
    @application.expects(:sync_host_registration).returns(true)
    @application.save.should == true
  end
  
  it "does not sync the host registration when writing the vhost failes during a save" do
    @application.expects(:write).returns(false)
    @application.expects(:sync_host_registration).never
    @application.save.should == false
  end
  
  it "writes its configuration file" do
    File.should.exist(@application.config_filename)
    @application.write
    File.should.exist(@application.config_filename)
  end
  
  it "deletes itself" do
    @application.expects(:unregister).returns(true)
    @application.delete.should == true
    File.should.not.exist?(@application.config_filename)
  end
end

describe "An Application, concerning a writeable application directory" do
  before do
    @path = File.join(temporary_directory, 'app')
    FileUtils.mkdir_p(File.join(@path, 'public'))
    
    @configuration = PassengerPane::Configuration.new(fake_apache_directory)
    @application   = PassengerPane::Application.new(@configuration, :path => @path)
  end
  
  it "restarts the app" do
    File.should.not.exist?(File.join(@path, 'tmp', 'restart.txt'))
    @application.restart
    File.should.exist?(File.join(@path, 'tmp', 'restart.txt'))
  end
end