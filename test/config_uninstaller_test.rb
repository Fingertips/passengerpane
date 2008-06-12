require File.expand_path('../test_helper', __FILE__)

describe "Config installer" do
  before do
    @tmp = File.expand_path('../tmp')
    FileUtils.mkdir_p @tmp
    @config_installer = File.expand_path('../../config_uninstaller.rb', __FILE__)
    
    @host = "het-manfreds-blog.local"
    
    @vhost_file = File.join(@tmp, 'test.vhost.conf')
    File.open(@vhost_file, 'w') { |f| f << 'bla' }
    
    @hosts_file = File.join(@tmp, 'test.hosts')
    File.open(@hosts_file, 'w') { |f| f << "127.0.0.1\t\t\tsome-other.local\n127.0.0.1\t\t\t#{@host}\n127.0.0.1\t\t\tyet-another.local" }
  end
  
  after do
    FileUtils.rm_rf @tmp
  end
  
  it "should remove a config file and the host entry" do
    `/usr/bin/env ruby #{@config_installer} '#{@vhost_file}' '#{@hosts_file}' '#{@host}'`
    
    File.should.not.exist @vhost_file
    File.read(@hosts_file).should == "127.0.0.1\t\t\tsome-other.local\n127.0.0.1\t\t\tyet-another.local"
  end
end