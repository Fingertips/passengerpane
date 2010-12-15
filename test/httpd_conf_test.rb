require File.expand_path('../test_helper', __FILE__)

describe "A HttpdConf" do
  before do
    @configuration = PassengerPane::Configuration.new
    @httpd = PassengerPane::HttpdConf.new(@configuration)
  end
  
  it "returns an include line for the passenger vhosts" do
    @httpd.passenger_vhost_include.should == "Include /private/etc/apache2/passenger_pane_vhosts/*.vhost.conf"
  end
  
  it "returns a passenger configuration snippet" do
    snippet = @httpd.passenger_configuration_snippet
    snippet.should.include("<IfModule passenger_module>")
    snippet.should.include('NameVirtualHost')
    snippet.should.include('VirtualHost')
    snippet.should.include(@httpd.passenger_vhost_include)
    snippet.should.include("</IfModule>")
  end
  
  it "knows when the passenger module is installed" do
    @httpd.expects(:`).with('/usr/sbin/httpd -D DUMP_MODULES 2>&1').returns(%{
Loaded Modules:
 core_module (static)
 rewrite_module (shared)
 bonjour_module (shared)
 passenger_module (shared)
Syntax OK
    }.strip)
    @httpd.passenger_module_installed?.should == true
  end
  
  it "knows when the passenger module is not installed" do
    @httpd.expects(:`).with('/usr/sbin/httpd -D DUMP_MODULES 2>&1').returns(%{
Loaded Modules:
 core_module (static)
 rewrite_module (shared)
 bonjour_module (shared)
Syntax OK
    }.strip)
    @httpd.passenger_module_installed?.should == false
  end
  
  it "knows if the configuration is valid" do
    @httpd.expects(:`).returns("Syntax OK")
    @httpd.should.be.valid
  end
  
  it "knows the configuration is valid when the last line says so" do
    @httpd.expects(:`).returns("[Wed Dec 15 11:17:25 2010] [warn] VirtualHost 172.16.0.3:80 overlaps with VirtualHost 172.16.0.3:80, the first has precedence, perhaps you need a NameVirtualHost directive
    [Wed Dec 15 11:17:25 2010] [warn] NameVirtualHost *:80 has no VirtualHosts
    Syntax OK")
    @httpd.should.be.valid
  end
  
  it "knows when the configuration is not valid" do
    @httpd.expects(:`).returns("Syntax error on line 2 of /private/etc/apache2/httpd.conf:
    Invalid command 'sdfasdadsf#', perhaps misspelled or defined by a module not included in the server con")
    @httpd.should.not.be.valid
  end
end

describe "A HttpdConf, with passenger configuration" do
  before do
    use_fake_apache_directory
    @configuration = PassengerPane::Configuration.new(fake_apache_directory)
    @httpd = @configuration.httpd
    contents = %{
# Secure (SSL/TLS) connections
#Include /private/etc/apache2/extra/httpd-ssl.conf
#
# Note: The following must must be present to support
#       starting without SSL on platforms with no /dev/random equivalent
#       but a statically compiled-in mod_ssl.
#
<IfModule ssl_module>
SSLRandomSeed startup builtin
SSLRandomSeed connect builtin
</IfModule>

LoadModule passenger_module /Library/Ruby/Gems/1.8/gems/passenger-3.0.0/ext/apache2/mod_passenger.so
PassengerRoot /Library/Ruby/Gems/1.8/gems/passenger-3.0.0
PassengerRuby /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby

Include /private/etc/apache2/other/*.conf

# Added by the Passenger preference pane
# Make sure to include the Passenger configuration (the LoadModule,
# PassengerRoot, and PassengerRuby directives) before this section.
<IfModule passenger_module>
  NameVirtualHost *:80
  <VirtualHost *:80>
    ServerName _default_
  </VirtualHost>
  Include /private/etc/apache2/passenger_pane_vhosts/*.conf
</IfModule>

Include /private/etc/apache2/manual_vhosts/*.conf
    }
    File.open(@httpd.filename, 'w') do |file|
      file.write(contents)
    end
  end
  
  it "has passenger configured" do
    @httpd.should.be.passenger_pane_configured
  end
  
  it "restarts apache" do
    @httpd.expects(:valid?).returns(true)
    @httpd.expects(:system).with(@configuration.apache_restart_command)
    @httpd.restart
  end
  
  it "does not restart when the configuration isn't valid" do
    @httpd.expects(:valid?).returns(false)
    @httpd.expects(:system).with(@configuration.apache_restart_command).never
    capture_stdout do
      @httpd.restart
    end.should == "[!] Apache configuration is not valid, skipping Apache restart\n"
  end
end

describe "A HttpdConf, without passenger configuration" do
  before do
    use_fake_apache_directory
    @httpd = PassengerPane::Configuration.new(fake_apache_directory).httpd
    File.open(@httpd.filename, 'w') do |file|
      file.write('')
    end
  end
  
  it "does not have passenger configured" do
    @httpd.should.not.be.passenger_pane_configured
  end
  
  it "configures passenger" do
    @httpd.configure_passenger
    @httpd.write
    @httpd.should.be.passenger_pane_configured
   end
end