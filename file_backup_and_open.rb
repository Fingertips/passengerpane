require 'fileutils'

class File
  class FileNotSuccesfullyWrittenError < StandardError; end
  
  def self.backup_and_open(file, mode, data)
    if file_already_exists = File.exist?(file)
      backup = "#{file}.bak"
      FileUtils.cp file, backup
      before = read(file)
    end
    
    open(file, mode) { |f| f << data }
    
    if file_already_exists
      if read(file) == before << data
        FileUtils.rm backup
      else
        FileUtils.rm file
        FileUtils.cp backup, file
        raise FileNotSuccesfullyWrittenError, "Unable to write to: #{file}"
      end
    end
  end
end