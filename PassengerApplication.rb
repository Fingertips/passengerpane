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
    include SharedPassengerBehaviour
    
    def existingApplications
      Dir.glob(File.join(PASSENGER_APPS_DIR, '*.vhost.conf')).map do |app|
        PassengerApplication.alloc.initWithFile(app)
      end
    end
    
    def startApplications(apps)
      data = serializedApplicationsData(apps)
      p "Starting Rails applications:\n#{data}"
      execute '/usr/bin/ruby', CONFIG_INSTALLER, data
      apps.each { |app| app.apply(false) }
    end
    
    def removeApplications(apps)
      data = serializedApplicationsData(apps)
      p "Removing applications: #{data}"
      execute '/usr/bin/ruby', CONFIG_UNINSTALLER, data
    end
    
    def serializedApplicationsData(apps)
      apps.to_ruby.map { |app| app.to_hash }.to_yaml
    end
  end
  
  kvc_accessor :host, :path, :dirty, :valid, :environment, :allow_mod_rewrite, :base_uri
  attr_reader :user_defined_data
  
  def init
    if super_init
      @environment = DEVELOPMENT
      @allow_mod_rewrite = false
      
      @new_app = true
      @dirty = @valid = false
      @host, @path, @base_uri, @user_defined_data = '', '', '', ''
      
      set_original_values!
      self
    end
  end
  
  def initWithFile(file)
    if init
      @new_app = false
      @valid = false
      
      data = File.read(file)
      
      data.gsub!(/\s*ServerName\s+(.+)\n/, '')
      @host = $1
      
      data.gsub!(/\s*DocumentRoot\s+"(.+)\/public"\n/, '')
      @path = $1
      
      data.gsub!(/\s*RailsEnv\s+(development|production)\n/, '')
      @environment = ($1 == 'development' ? DEVELOPMENT : PRODUCTION)
      
      data.gsub!(/\s*RailsAllowModRewrite\s+(off|on)\n/, '')
      @allow_mod_rewrite = ($1 == 'on')
      
      data.gsub!(/\s*RailsBaseURI\s+(.+)\n/, '')
      @base_uri = $1 unless $1.nil?
      
      data.gsub!(/\s*<VirtualHost.+\n*/, '')
      data.gsub!(/\s*<\/VirtualHost>\n*/, '')
      @user_defined_data = data
      
      set_original_values!
      self
    end
  end
  
  def initWithPath(path)
    if init
      mark_dirty!
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
  
  def apply(save_config = nil)
    p "Applying changes to Rails application: #{@path}"
    (@new_app ? start : restart) unless save_config == false
    # todo: check if it went ok before assumin so.
    @new_app = self.dirty = self.valid = false
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
    mark_dirty!
    
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
  
  def mark_dirty!
    self.dirty = true
    PrefPanePassenger.sharedInstance.applicationMarkedDirty self
  end
  
  def to_hash
    {
      'config_path' => config_path,
      'host' => @host.to_s,
      'path' => @path.to_s,
      'environment' => @environment == DEVELOPMENT ? 'development' : 'production',
      'allow_mod_rewrite' => (@allow_mod_rewrite == true || @allow_mod_rewrite == 1),
      'base_uri' => @base_uri,
      'user_defined_data' => @user_defined_data
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