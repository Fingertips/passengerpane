require File.expand_path('../test_helper', __FILE__)

describe "DirectoryServices" do
  it "returns registered hosts" do
    expected = %w(assets0.local assets1.local)
    PassengerPane::DirectoryServices.expects(:`).with('/usr/bin/dscl localhost -list /Local/Default/Hosts').returns(expected.join("\n"))
    PassengerPane::DirectoryServices.registered_hosts.should == expected
  end
  
  it "registers hosts" do
    hosts = %w(assets0.local assets1.local)
    hosts.each do |host|
      PassengerPane::DirectoryServices.expects(:system).with("/usr/bin/dscl localhost -create /Local/Default/Hosts/#{host} IPAddress 127.0.0.1")
    end
    PassengerPane::DirectoryServices.register(hosts)
  end
  
  it "unregisters hosts" do
    hosts = %w(assets0.local assets1.local)
    hosts.each do |host|
      PassengerPane::DirectoryServices.expects(:system).with("/usr/bin/dscl localhost -delete /Local/Default/Hosts/#{host}")
    end
    PassengerPane::DirectoryServices.unregister(hosts)
  end
end