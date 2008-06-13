require File.expand_path('../test_helper', __FILE__)
require 'yaml'

describe "Config installer" do
  before do
    @tmp = File.expand_path('../tmp')
    FileUtils.mkdir_p @tmp
    @config_installer = File.expand_path('../../config_installer.rb', __FILE__)
  end
  
  after do
    FileUtils.rm_rf @tmp
  end
  
  it "should create a config file" do
    vhost_file = File.join(@tmp, 'test.vhost.conf')
    hosts_file = File.join(@tmp, 'test.hosts')
    File.open(hosts_file, 'w') { |f| f << "127.0.0.1\t\t\tsome-other.local" }
    
    host = "het-manfreds-blog.local"
    path = "/User/het-manfred/rails code/blog"
    
    file_which_is_created_by_the_optional_extra_command = File.join(@tmp, 'file_from_extra_command.txt')
    
    `/usr/bin/env ruby #{@config_installer} '#{hosts_file}' '#{ [{ 'config_path' => vhost_file, 'host' => host, 'path' => path }].to_yaml }' 'touch #{file_which_is_created_by_the_optional_extra_command}'`
    
    vhost = File.read(vhost_file)
    vhost.should == "<VirtualHost *:80>\n  ServerName #{host}\n  DocumentRoot \"#{path}/public\"\n</VirtualHost>\n"
    
    hosts = File.read(hosts_file)
    hosts.should == "127.0.0.1\t\t\tsome-other.local\n127.0.0.1\t\t\t#{host}"
    
    File.should.exist file_which_is_created_by_the_optional_extra_command
  end
end