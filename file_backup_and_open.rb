require 'fileutils'

class String
  def bypass_safe_level_1
    str = dup
    str.untaint
    str
  end
end

class File
  class FileNotSuccesfullyWrittenError < StandardError; end
  
  class << self
    def backup_and_open(file, mode, data)
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
    
    def backup_and_remove_data(file, data)
      backup = "#{file}.bak"
      FileUtils.cp file, backup
      
      should_become = read(file).sub(data, '')
      open(file, 'w') { |f| f << should_become }
      
      if read(file) == should_become
        FileUtils.rm backup
      else
        FileUtils.rm file
        FileUtils.cp backup, file
        raise FileNotSuccesfullyWrittenError, "Unable to write to: #{file}"
      end
    end
  end
end