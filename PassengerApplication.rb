require 'osx/cocoa'
include OSX

require 'yaml'
require File.expand_path('../shared_passenger_behaviour', __FILE__)

class PassengerApplication < NSObject
  include SharedPassengerBehaviour
  
  CONFIG_UNINSTALLER = File.expand_path('../config_uninstaller.rb', __FILE__)
  CONFIG_INSTALLER   = File.expand_path('../config_installer.rb', __FILE__)
  
  DEVELOPMENT = 0
  PRODUCTION = 1
  
  def self.startApplications(apps)
    data = apps.to_ruby.map { |app| app.to_hash }.to_yaml
    SharedPassengerBehaviour.p "Starting Rails applications (restarting Apache gracefully):\n#{data}"
    SharedPassengerBehaviour.execute "/usr/bin/env ruby '#{CONFIG_INSTALLER}' '/etc/hosts' '#{data}' '/usr/sbin/apachectl graceful'"
  end
  
  kvc_accessor :host, :path, :dirty, :valid, :environment, :override_rewrite_rules
  
  def init
    if super_init
      @environment = DEVELOPMENT
      @override_rewrite_rules = false
      
      @new_app = true
      @dirty = @valid = false
      @host, @path = '', ''
      self
    end
  end
  
  def initWithFile(file)
    if init
      @new_app = false
      @valid = true
      data = File.read(file)
      @host = data.match(/ServerName\s+(.+)\n/)[1]
      @path = data.match(/DocumentRoot\s+"(.+)\/public"\n/)[1]
      self
    end
  end
  
  def initWithPath(path)
    if init
      @path = path
      set_default_host_from_path(path)
      self
    end
  end
  
  def apply(sender = nil)
    p "apply"
    @new_app ? start : restart
  end
  
  def start
    p "Starting Rails application (restarting Apache gracefully): #{@path}"
    save_config! '/usr/sbin/apachectl graceful'
  end
  
  def restart(sender = nil)
    p "Restarting Rails application: #{@path}"
    save_config! if @dirty
    Kernel.system("/usr/bin/touch '#{File.join(@path, 'tmp', 'restart.txt')}'")
  end
  
  def remove
    p "Removing application: #{path}"
    execute "/usr/bin/env ruby '#{CONFIG_UNINSTALLER}' '/etc/hosts' '#{config_path}' '#{@host}'"
  end
  
  def save_config!(extra_command = nil)
    p "Saving configuration: #{config_path}"
    command = "/usr/bin/env ruby '#{CONFIG_INSTALLER}' '/etc/hosts' '#{[to_hash].to_yaml}'"
    command << " '#{extra_command}'" if extra_command
    execute command
  end
  
  def config_path
    @config_path ||= File.join(USERS_APACHE_PASSENGER_APPS_DIR, "#{@host}.vhost.conf")
  end
  
  def rbSetValue_forKey(value, key)
    super
    self.dirty = true
    set_default_host_from_path(@path) if key == 'path' && (@host.nil? || @host.empty?) && (!@path.nil? && !@path.empty?)
    self.valid = (!@host.nil? && !@host.empty? && !@path.nil? && !@path.empty?)
  end
  
  def to_hash
    {'config_path' => config_path, 'host' => @host.to_s, 'path' => @path.to_s}
  end
  
  private
  
  def set_default_host_from_path(path)
    self.host = "#{File.basename(path).downcase}.local"
  end
end