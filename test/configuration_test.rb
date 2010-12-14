require File.expand_path('../test_helper', __FILE__)

describe "Configuration" do
  it "raises an argument error when an unknown configuration key is set" do
    configuration = PassengerPane::Configuration.new
    lambda {
      begin
        configuration.set({'unknown' => 'value'})  
      rescue ArgumentError => e
        e.message.should.start_with('There is no configuration named `unknown\'')
      end
    }.should.not.raise
  end
  
  it "initializes a configuration with default values" do
    configuration = PassengerPane::Configuration.new
  end
  
  it "returns all applications" do
    apps = mock('Applications')
    PassengerPane::Application.stubs(:all).returns(apps)
    PassengerPane::Configuration.new.applications.should == apps
  end
end

describe "A Configuration" do
  before do
    use_fake_apache_directory
    @configuration = PassengerPane::Configuration.new(fake_apache_directory)
  end
  
  it "returns an httpd configuration instance" do
    @configuration.httpd.should.be.kind_of?(PassengerPane::HttpdConf)
  end
end