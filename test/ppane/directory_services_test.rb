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

describe "DirectoryServices, concerning a hosts file hack to make Safari find hosts on Lion" do
  before do
    PassengerPane::DirectoryServices.stubs(:broken?).returns(true)
    
    @etc_hosts_file = File.join(temporary_directory, 'hosts')
    PassengerPane::DirectoryServices.stubs(:etc_hosts_file).returns(@etc_hosts_file)
    FileUtils.touch(@etc_hosts_file)
    
    @hosts = %w(assets0.local assets1.local cms.local admin.cms.local)
    PassengerPane::DirectoryServices.stubs(:`).with('/usr/bin/dscl localhost -list /Local/Default/Hosts').returns(@hosts.join("\n"))
  end
  
  it "returns the registered hosts separated by whitespace" do
    PassengerPane::DirectoryServices.hosts_as_string.should == @hosts.join(' ')
  end
  
  it "writes registered hosts to a file" do
    PassengerPane::DirectoryServices.write_to_hosts_file
    File.read(@etc_hosts_file).should.include PassengerPane::DirectoryServices.hosts_configuration_line
  end
  
  it "does not touch the rest of the hosts file" do
    original_contents = "127.0.0.1 localhost\n"
    File.open(@etc_hosts_file, 'w') do |file|
      file.write(original_contents)
    end
    PassengerPane::DirectoryServices.write_to_hosts_file
    File.read(@etc_hosts_file).should.include(original_contents)
  end
  
  it "does not write a second configuration line when there already is one" do
    original_contents = "#{PassengerPane::DirectoryServices.hosts_configuration_line}\n127.0.0.1 localhost\n"
    File.open(@etc_hosts_file, 'w') do |file|
      file.write(original_contents)
    end
    PassengerPane::DirectoryServices.write_to_hosts_file
    File.read(@etc_hosts_file).should == "127.0.0.1 localhost\n#{PassengerPane::DirectoryServices.hosts_configuration_line}\n"
  end
end