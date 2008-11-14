require File.expand_path('../test_helper', __FILE__)
require 'config_uninstaller'

describe "ConfigUninstaller" do
  before do
    @tmp = File.expand_path('../tmp')
    FileUtils.mkdir_p @tmp
    @config_installer = File.expand_path('../../config_uninstaller.rb', __FILE__)
    
    @host = "het-manfreds-blog.local"
    @aliases = "manfred-s-blog.local my-blog.local"
    @vhost_file = File.join(@tmp, 'test.vhost.conf')
    
    File.open(@vhost_file, 'w') { |f| f << 'bla' }
    
    @uninstaller = ConfigUninstaller.new([{ 'config_path' => @vhost_file, 'host' => @host, 'aliases' => @aliases }].to_yaml)
  end
  
  after do
    FileUtils.rm_rf @tmp
  end
  
  it "should initialize" do
    @uninstaller.data.should == [{ 'config_path' => @vhost_file, 'host' => @host, 'aliases' => @aliases }]
  end
  
  it "should remove the ServerName entry and the ServerAlias entries from the hosts db" do
    @uninstaller.expects(:system).with("/usr/bin/dscl localhost -delete /Local/Default/Hosts/het-manfreds-blog.local")
    @uninstaller.expects(:system).with("/usr/bin/dscl localhost -delete /Local/Default/Hosts/manfred-s-blog.local")
    @uninstaller.expects(:system).with("/usr/bin/dscl localhost -delete /Local/Default/Hosts/my-blog.local")
    @uninstaller.remove_from_hosts(0)
  end
  
  it "should return the path to the vhost config" do
    @uninstaller.config_path(0).should == "#{PassengerPaneConfig::PASSENGER_APPS_DIR}/het-manfreds-blog.local.#{PassengerPaneConfig::PASSENGER_APPS_EXTENSION}"
  end
  
  it "should remove the vhost config file" do
    @uninstaller.stubs(:config_path).returns(@vhost_file)
    @uninstaller.remove_vhost_conf(0)
    File.should.not.exist @vhost_file
  end
  
  it "should restart Apache" do
    @uninstaller.expects(:system).with(PassengerPaneConfig::APACHE_RESTART_COMMAND)
    @uninstaller.restart_apache!
  end
  
  it "should remove multiple applications in one go" do
    uninstaller = ConfigUninstaller.any_instance
    
    uninstaller.expects(:remove_from_hosts).with(0)
    uninstaller.expects(:remove_from_hosts).with(1)
    
    uninstaller.expects(:remove_vhost_conf).with(0)
    uninstaller.expects(:remove_vhost_conf).with(1)
    
    uninstaller.expects(:restart_apache!)
    
    ConfigUninstaller.new([{}, {}].to_yaml).uninstall!
  end
end