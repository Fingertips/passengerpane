require 'osx/cocoa'
include OSX

class PassengerApplication < NSObject
  CONFIG_PATH = "/etc/apache2/users/passenger_apps"
  CONFIG_INSTALLER = File.expand_path('../config_installer.rb', __FILE__)
  
  kvc_accessor :host, :path
  
  def init
    if super_init
      @host, @path = '', ''
      self
    end
  end
  
  def initWithFile(file)
    if init
      data = File.read(file)
      @host = data.match(/ServerName\s+(.+)\n/)[1]
      @path = data.match(/DocumentRoot\s+"(.+)\/public"\n/)[1]
      self
    end
  end
  
  # def restart(sender)
  #   p "Restarting Rails application: #{@path}"
  #   save_config!
  # end
  # 
  # def remove!
  #   p "remove #{self}"
  # end
  # 
  def save_config!
    execute "/usr/bin/env ruby '#{CONFIG_INSTALLER}' '#{config_path}' '/etc/hosts' '#{@host}' '#{@path}'"
  end
  
  def config_path
    @config_path ||= "#{CONFIG_PATH}/#{@host}.vhost.conf"
  end
  
  private
  
  def execute(command)
    script = NSAppleScript.alloc.initWithSource("do shell script \"#{command}\" with administrator privileges")
    script.performSelector_withObject("executeAndReturnError:", nil)
  end
end