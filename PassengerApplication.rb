require 'osx/cocoa'
include OSX

require File.expand_path('../shared_passenger_behaviour', __FILE__)

class PassengerApplication < NSObject
  include SharedPassengerBehaviour
  
  CONFIG_UNINSTALLER = File.expand_path('../config_uninstaller.rb', __FILE__)
  CONFIG_INSTALLER   = File.expand_path('../config_installer.rb', __FILE__)
  
  kvc_accessor :host, :path
  
  def init
    if super_init
      @new_app = true
      @dirty = false
      @host, @path = '', ''
      self
    end
  end
  
  def initWithFile(file)
    if init
      @new_app = false
      data = File.read(file)
      @host = data.match(/ServerName\s+(.+)\n/)[1]
      @path = data.match(/DocumentRoot\s+"(.+)\/public"\n/)[1]
      self
    end
  end
  
  def start
    p "Starting Rails application (restarting Apache gracefully): #{@path}"
    save_config!
    execute '/usr/sbin/apachectl graceful'
  end
  
  def restart(sender = nil)
    p "Restarting Rails application: #{@path}"
    save_config! if @dirty
    Kernel.system("/usr/bin/touch '#{File.join(@path, 'tmp', 'restart.txt')}'")
  end
  
  def remove
    p "Removing application: #{path}"
    execute "/usr/bin/env ruby '#{CONFIG_UNINSTALLER}' '#{config_path}' '/etc/hosts' '#{@host}'"
  end
  
  def save_config!
    p "Saving configuration: #{config_path}"
    execute "/usr/bin/env ruby '#{CONFIG_INSTALLER}' '#{config_path}' '/etc/hosts' '#{@host}' '#{@path}'"
  end
  
  def config_path
    @config_path ||= File.join(USERS_APACHE_PASSENGER_APPS_DIR, "#{@host}.vhost.conf")
  end
  
  def rbSetValue_forKey(value, key)
    super
    @dirty = true
    (@new_app ? start : restart) unless @host.empty? or @path.empty?
  end
end