require File.expand_path('../test_helper', __FILE__)
require 'config_installer'
require 'yaml'

describe "ConfigInstaller" do
  before do
    @tmp = File.expand_path('../tmp').bypass_safe_level_1
    FileUtils.mkdir_p @tmp
    @vhost_file = File.join(@tmp, 'test.vhost.conf')
    
    @data = {
      'config_path' => @vhost_file,
      'host' => 'het-manfreds-blog.local',
      'path' => '/User/het-manfred/rails code/blog',
      'environment' => 'production',
      'allow_mod_rewrite' => true
    }
    
    @installer = ConfigInstaller.new([@data].to_yaml)
  end
  
  after do
    FileUtils.rm_rf @tmp
  end
  
  it "should initialize" do
    @installer.data.should == [{
      'config_path' => @vhost_file,
      'host' => 'het-manfreds-blog.local',
      'path' => '/User/het-manfred/rails code/blog',
      'environment' => 'production',
      'allow_mod_rewrite' => true
    }]
  end
  
  it "should be able to add a new entry to the hosts" do
    @installer.expects(:system).with("/usr/bin/dscl localhost -create /Local/Default/Hosts/het-manfreds-blog.local IPAddress 127.0.0.1")
    @installer.add_to_hosts(0)
  end
  
  it "should create a new vhost conf file" do
    @installer.create_vhost_conf(0)
    
    File.read(@vhost_file.bypass_safe_level_1).should == %{
<VirtualHost *:80>
  ServerName het-manfreds-blog.local
  DocumentRoot "/User/het-manfred/rails code/blog/public"
  RailsEnv production
  RailsAllowModRewrite on
</VirtualHost>
}.sub(/^\n/, '')
  end
  
  xit "should not execute an extra command if there is none" do
    @installer.expects(:system).times(0)
    @installer.execute_extra_command
  end
  
  xit "should execute an extra command if there is one" do
    tmp_file = File.join(@tmp, 'file_from_extra_command.txt')
    ConfigInstaller.new([].to_yaml, "touch #{tmp_file}").execute_extra_command
    File.should.exist tmp_file
  end
  
  it "should restart Apache" do
    @installer.expects(:system).with("/bin/launchctl stop org.apache.httpd")
    @installer.restart_apache!
  end
  
  it "should be able to take a serialized array of hashes and do all the work necessary in one go" do
    installer = ConfigInstaller.any_instance
    
    installer.expects(:add_to_hosts).with(0)
    installer.expects(:add_to_hosts).with(1)
    
    installer.expects(:create_vhost_conf).with(0)
    installer.expects(:create_vhost_conf).with(1)
    
    #installer.expects(:execute_extra_command)
    installer.expects(:restart_apache!)
    
    ConfigInstaller.new([{}, {}].to_yaml, 'extra command').install!
  end
end