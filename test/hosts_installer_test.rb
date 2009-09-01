require File.expand_path('../test_helper', __FILE__)

describe "HostsInstaller" do
  before do
    @installer = HostsInstaller.new(%w{ blog.local paste.local })
  end
  
  it "should add the hosts to the hosts database" do
    @installer.expects(:system).with("/usr/bin/dscl localhost -create /Local/Default/Hosts/blog.local IPAddress 127.0.0.1")
    @installer.expects(:system).with("/usr/bin/dscl localhost -create /Local/Default/Hosts/paste.local IPAddress 127.0.0.1")
    @installer.install!
  end
end