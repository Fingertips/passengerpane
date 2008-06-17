require File.expand_path('../test_helper', __FILE__)

describe "Config installer" do
  before do
    @tmp = File.expand_path('../tmp', __FILE__)
    FileUtils.mkdir_p @tmp
    @config_installer = File.expand_path('../../passenger_config_installer.rb', __FILE__)
    @conf_file = File.join(@tmp, 'eloy.conf')
    File.open(@conf_file, 'w') { |f| f << "</Directory>" }
    `/usr/bin/ruby -T1 '#{@config_installer}' '#{@conf_file}'`
  end
  
  after do
    FileUtils.rm_rf @tmp
  end
  
  it "should append the passenger configuration to an existing config" do
    version = `/usr/bin/gem list passenger`.rstrip.match(/\(([\d\.]+)[,\)]/)[1]
    
    File.read(@conf_file).should == %{
</Directory>

LoadModule passenger_module /Library/Ruby/Gems/1.8/gems/passenger-#{version}/ext/apache2/mod_passenger.so
PassengerRoot /Library/Ruby/Gems/1.8/gems/passenger-#{version}
PassengerRuby /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby

Include #{File.join(@tmp, 'eloy-passenger-apps', '*.vhost.conf')}
}.sub(/^\n/, '')
  end
  
  it "should create a passenger apps directory for the user" do
    File.should.be.directory File.join(@tmp, "eloy-passenger-apps")
  end
end