require 'fileutils'

class File
  class FileNotSuccesfullyWrittenError < StandardError; end
  
  def self.backup_and_open(file, mode, data)
    if file_exists = File.exist?(file)
      FileUtils.cp file, "#{file}.bak"
      before = read(file)
    end
    
    open(file, mode) { |f| f << data }
    unless !file_exists or read(file) == before << data
      raise FileNotSuccesfullyWrittenError
    end
  end
end