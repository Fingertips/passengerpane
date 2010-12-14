module TestHelper
  module FakeApacheDirectory
    def apache_directory_fixture
      File.expand_path('../../fake/etc/apache2', __FILE__)
    end
    
    def fake_apache_directory
      File.join(temporary_directory, 'apache2')
    end
    
    def use_fake_apache_directory
      FileUtils.cp_r(apache_directory_fixture, fake_apache_directory)
    end
  end
end