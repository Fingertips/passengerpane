require 'fileutils'

module TestHelper
  module TemporaryDirectory
    def temporary_directory
      File.expand_path('../../../tmp/.test', __FILE__)
    end
    
    def setup_temporary_directory
      FileUtils.mkdir_p(temporary_directory)
    end
    
    def teardown_temporary_directory
      FileUtils.rm_rf(temporary_directory)
    end
    
    def setup
      super
      teardown_temporary_directory
      setup_temporary_directory
    end
  end
end