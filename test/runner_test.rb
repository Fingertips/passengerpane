require File.expand_path('../test_helper', __FILE__)

describe "Runner" do
  before do
    use_fake_apache_directory
    
    application_directory = File.join(temporary_directory, 'app')
    %w(app public).each do |directory|
      FileUtils.mkdir_p(File.join(application_directory, directory))
    end
    
    @conf = PassengerPane::Configuration.new(fake_apache_directory)
    @app  = PassengerPane::Application.new(@conf, :path => application_directory)
    
    PassengerPane::Configuration.stubs(:auto).returns(@conf)
  end
  
  it "lists all configured applications" do
    output = capture_stdout do
      PassengerPane::Runner.run({}, %w(list))
    end
    @conf.applications.each do |app|
      output.should.include?(app.host)
    end
  end
  
  it "registers all configured hostnames" do
    @conf.applications.each do |app|
      PassengerPane::DirectoryServices.expects(:register).with(app.to_hash['hosts'])
    end
    capture_stdout do
      PassengerPane::Runner.run({}, %w(register))
    end
  end
  
  it "shows information about the system" do
    @conf.httpd.stubs(:passenger_module_installed?).returns(true)
    PassengerPane::DirectoryServices.stubs(:registered_hosts).returns(%w(assets.skit.local skit.local weblog.local))
    
    output = capture_stdout do
      PassengerPane::Runner.run({}, %w(info))
    end
    
    output.should.include('Passenger installed:  yes')
    output.should.include('Passenger configured: yes')
  end
  
  it "shows information about the system in YAML" do
    @conf.httpd.stubs(:passenger_module_installed?).returns(true)
    PassengerPane::DirectoryServices.stubs(:registered_hosts).returns(%w(assets.skit.local skit.local weblog.local))
    
    output = capture_stdout do
      PassengerPane::Runner.run({'m' => nil}, %w(info))
    end
    
    output.should.include('passenger_pane_configured: true')
    output.should.include('passenger_module_installed: true')
  end
  
  it "configures Apache for use with the Passenger Pane" do
    Kernel.allow_backtick = true
    @conf.httpd.stubs(:restart)
    File.open(@conf.httpd.filename, 'w') { |file| file.write('') }
    
    capture_stdout do
      PassengerPane::Runner.run({}, %w(configure))
    end
    
    @conf.httpd.should.be.passenger_pane_configured
  end
  
  it "does not configure Apache for use with the Passenger Pane if it's already configured" do
    @conf.httpd.expects(:write).never
    capture_stdout do
      PassengerPane::Runner.run({}, %w(configure))
    end
  end
  
  it "adds a new application to the configuration" do
    PassengerPane::DirectoryServices.expects(:register).with(%w(app.local))
    capture_stdout do
      PassengerPane::Runner.run({}, ['add', @app.path])
    end
    @conf.applications.map { |app| app.host }.should.include('app.local')
  end
  
  it "updates an application" do
    @conf.httpd.stubs(:restart)
    PassengerPane::DirectoryServices.expects(:register).with(%w(blog.local)).returns(true)
    PassengerPane::DirectoryServices.expects(:unregister).with(%w(staging.blog.local)).returns(true)
    
    app = PassengerPane::Application.find(@conf, :host => 'staging.blog.local')
    capture_stdout do
      PassengerPane::Runner.run({'host' => 'blog.local'}, ['update', app.host])
    end
    
    app.contents = nil
    app._parse
    app.host.should == 'blog.local'
  end
  
  it "deletes an application" do
    @conf.httpd.stubs(:restart)
    PassengerPane::DirectoryServices.expects(:unregister).with(%w(staging.blog.local)).returns(true)
    
    app = PassengerPane::Application.find(@conf, :host => 'staging.blog.local')
    capture_stdout do
      PassengerPane::Runner.run({}, ['delete', app.host])
    end
    
    File.should.not.exist?(app.config_filename)
  end
  
  it "restarts an application" do
    PassengerPane::DirectoryServices.stubs(:register).returns(true)
    @app.should.save
    
    File.should.not.exist?(File.join(@app.path, 'tmp', 'restart.txt'))
    capture_stdout do
      PassengerPane::Runner.run({}, ['restart', @app.host])
    end
    File.should.exist?(File.join(@app.path, 'tmp', 'restart.txt'))
  end
  
  it "restarts Apache" do
    @conf.httpd.expects(:valid?).returns(true)
    @conf.httpd.expects(:system).with(@conf.apache_restart_command).returns(true)
    capture_stdout do
      PassengerPane::Runner.run({}, %w(restart))
    end
  end
end

describe "Runner, interacting through YAML" do
end