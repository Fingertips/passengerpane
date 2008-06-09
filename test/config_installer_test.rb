require File.expand_path('../test_helper', __FILE__)

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
    vhost_config = File.join(@tmp, 'test.vhost.conf')
    host = "het-manfreds-blog.local"
    path = "/User/het-manfred/rails code/blog"
    
    `/usr/bin/env ruby #{@config_installer} '#{vhost_config}' '#{host}' '#{path}'`
    
    vhost = File.read(vhost_config)
    vhost.should == "<VirtualHost *:80>\n  ServerName #{host}\n  DocumentRoot \"#{path}/public\"\n</VirtualHost>\n"
  end
end