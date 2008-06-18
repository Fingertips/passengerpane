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
  
  class << self
    def startApplications(apps)
      data = serializedApplicationsData(apps)
      SharedPassengerBehaviour.p "Starting Rails applications (restarting Apache gracefully):\n#{data}"
      SharedPassengerBehaviour.execute '/usr/bin/ruby', CONFIG_INSTALLER, data
      apps.each { |app| app.reset_dirty_and_valid! }
    end
  
    def removeApplications(apps)
      data = serializedApplicationsData(apps)
      SharedPassengerBehaviour.p "Removing applications: #{data}"
      SharedPassengerBehaviour.execute '/usr/bin/ruby', CONFIG_UNINSTALLER, data
    end
  
    def serializedApplicationsData(apps)
      apps.to_ruby.map { |app| app.to_hash }.to_yaml
    end
  end
  
  kvc_accessor :host, :path, :dirty, :valid, :environment, :allow_mod_rewrite, :base_uri
  
  def init
    if super_init
      @environment = DEVELOPMENT
      @allow_mod_rewrite = false
      
      @new_app = true
      @dirty = @valid = false
      @host, @path, @base_uri = '', '', ''
      
      set_original_values!
      self
    end
  end
  
  def initWithFile(file)
    if init
      @new_app = false
      @valid = false
      data = File.read(file)
      @host = data.match(/ServerName\s+(.+)\n/)[1]
      @path = data.match(/DocumentRoot\s+"(.+)\/public"\n/)[1]
      @environment = (data.match(/RailsEnv\s+(development|production)\n/)[1] == 'development' ? DEVELOPMENT : PRODUCTION)
      @allow_mod_rewrite = (data.match(/RailsAllowModRewrite\s+(off|on)\n/)[1] == 'on')
      
      if match = data.match(/RailsBaseURI\s+(.+)\n/)
        @base_uri = match[1]
      end
      
      set_original_values!
      self
    end
  end
  
  def initWithPath(path)
    if init
      @dirty = true
      @path = path
      set_default_host_from_path(path)
      
      set_original_values!
      self
    end
  end
  
  def new_app?
    @new_app
  end
  
  def dirty?
    @dirty
  end
  
  def valid?
    @valid
  end
  
  def apply(sender = nil)
    p "apply"
    @new_app ? start : restart
    # todo: check if it went ok before assumin so.
    reset_dirty_and_valid!
  end
  
  def reset_dirty_and_valid!
    self.dirty = self.valid = false
  end
  
  def start
    p "Starting Rails application (restarting Apache gracefully): #{@path}"
    save_config!
  end
  
  def restart(sender = nil)
    p "Restarting Rails application: #{@path}"
    execute('/usr/bin/ruby', CONFIG_UNINSTALLER, [@original_values].to_yaml) unless @host == @original_values['host']
    save_config! if @dirty
    Kernel.system("/usr/bin/touch '#{File.join(@path, 'tmp', 'restart.txt')}'")
  end
  
  def save_config!
    p "Saving configuration: #{config_path}"
    execute '/usr/bin/ruby', CONFIG_INSTALLER, [to_hash].to_yaml
  end
  
  def config_path
    File.join(PASSENGER_APPS_DIR, "#{@host}.vhost.conf")
  end
  
  def rbValueForKey(key)
    key == 'host' ? "#{@host}#{@base_uri}" : super
  end
  
  def rbSetValue_forKey(value, key)
    super
    self.dirty = true
    
    if key == 'host'
      if value.to_s =~ /^(.+?)(\/.+)$/
        @host, @base_uri = $1, $2
      else
        @base_uri = ''
      end
    end
    
    set_default_host_from_path(@path) if key == 'path' && (@host.nil? || @host.empty?) && (!@path.nil? && !@path.empty?)
    self.valid = (!@host.nil? && !@host.empty? && !@path.nil? && !@path.empty?)
  end
  
  def to_hash
    {
      'config_path' => config_path,
      'host' => @host.to_s,
      'path' => @path.to_s,
      'environment' => @environment == DEVELOPMENT ? 'development' : 'production',
      'allow_mod_rewrite' => (@allow_mod_rewrite == true || @allow_mod_rewrite == 1),
      'base_uri' => @base_uri
    }
  end
  
  def revert(sender = nil)
    @original_values.each do |key, value|
      send "#{key}=", value
    end
    self.valid = self.dirty = false
  end
  
  private
  
  def set_original_values!
    @original_values = { 'host' => @host, 'path' => @path, 'environment' => @environment, 'allow_mod_rewrite' => @allow_mod_rewrite, 'base_uri' => @base_uri }
  end
  
  def set_default_host_from_path(path)
    self.host = "#{File.basename(path).downcase}.local"
  end
end