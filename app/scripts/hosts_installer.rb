require 'osx/cocoa'

class String
  def bypass_safe_level_1
    str = dup
    str.untaint
    str
  end
end

class HostsInstaller
  def initialize(hosts = ARGV)
    @hosts = hosts
  end
  
  def add_hosts
    @hosts.each do |host|
      OSX::NSLog("Will add host: #{host}")
      system "/usr/bin/dscl localhost -create /Local/Default/Hosts/#{host.bypass_safe_level_1} IPAddress 127.0.0.1"
    end
  end
  
  def install!
    add_hosts
  end
end

if $0 == __FILE__
  HostsInstaller.new(ARGV).install!
end