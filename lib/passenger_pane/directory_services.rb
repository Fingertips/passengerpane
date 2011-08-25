module PassengerPane
  class DirectoryServices
    def self.registered_hosts
      `/usr/bin/dscl localhost -list /Local/Default/Hosts`.split("\n")
    end
    
    def self.register(hosts)
      hosts.each do |host|
        system(trust("/usr/bin/dscl localhost -create /Local/Default/Hosts/#{host} IPAddress 127.0.0.1"))
      end
    end
    
    def self.unregister(hosts)
      hosts.each do |host|
        system(trust("/usr/bin/dscl localhost -delete /Local/Default/Hosts/#{host}"))
      end
    end
    
    def self.broken?
      !(`sw_vers -productVersion`.strip < '10.7')
    end
    
    def self.hosts_as_string
      registered_hosts.join(' ')
    end
    
    def self.open_and_lock(filename)
      file = File.open(filename, File::RDWR)
      begin
        file.flock(File::LOCK_EX)
        yield file
      ensure
        file.flock(File::LOCK_UN)
        file.close
      end
    end
    
    def self.etc_hosts_file
      '/etc/hosts'
    end
    
    def self.marker
      "Maintained by Passenger Pane"
    end
    
    def self.hosts_configuration_line
      "127.0.0.1 #{hosts_as_string} # #{marker}"
    end
    
    def self.write_to_hosts_file
      open_and_lock(etc_hosts_file) do |file|
        contents = file.read
        lines = contents.split("\n")
        
        lines.each_with_index do |line, index|
          if line.include?(marker)
            lines.delete_at(index)
            break
          end
        end if contents.include?(marker)
        
        lines << "#{hosts_configuration_line}\n"
        file.truncate(0)
        file.seek(0)
        
        file.write(lines.join("\n"))
      end
    rescue Errno::EACCES
      puts "[!] Didn't write hosts configuration to #{etc_hosts_file}, because I couldn't open it"
    end
    
    def self.write_to_hosts_file_if_broken
      write_to_hosts_file if broken?
    end
  end
end