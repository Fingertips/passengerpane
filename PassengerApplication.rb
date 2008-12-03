require 'osx/cocoa'
include OSX

require 'fileutils'
require 'yaml'
require File.expand_path('../passenger_pane_config', __FILE__)
require File.expand_path('../shared_passenger_behaviour', __FILE__)

class PassengerApplication < NSObject
  include SharedPassengerBehaviour
  
  CONFIG_UNINSTALLER = File.expand_path('../config_uninstaller.rb', __FILE__)
  CONFIG_INSTALLER   = File.expand_path('../config_installer.rb', __FILE__)
  
  RAILS = 'rails'
  RACK = 'rack'
  
  DEVELOPMENT = 0
  PRODUCTION = 1
  
  class << self
    include SharedPassengerBehaviour
    
    def existingApplications
      Dir.glob(File.join(PassengerPaneConfig::PASSENGER_APPS_DIR, "*.#{PassengerPaneConfig::PASSENGER_APPS_EXTENSION}")).map do |app|
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
  
  kvc_accessor :host, :path, :aliases, :dirty, :valid, :revertable, :environment
  attr_accessor :user_defined_data, :vhostname
  
  def init
    if super_init
      @environment = DEVELOPMENT
      
      @new_app = true
      @dirty = @valid = @revertable = false
      @host, @path, @aliases, @user_defined_data = '', '', '', ''
      @vhostname = '*:80'
      
      set_original_values!
      self
    end
  end
  
  def initWithFile(file)
    if init
      @new_app = false
      @valid = false
      load_data_from_vhost_file(file)
      set_original_values!
      self
    end
  end
  
  def initWithPath(path)
    if init
      mark_dirty!
      
      @path = path
      set_default_host_from_path(path)
      
      @valid = true
      set_original_values!
      self
    end
  end
  
  def application_type
    @application_type ||= check_application_type
  end
  
  def new_app?; @new_app; end
  def dirty?;   @dirty;   end
  def valid?;   @valid;   end
  def revertable?; @revertable; end
  
  def apply(save_config = nil)
    unless @valid
      p "Not applying changes to invalid Rails application: #{@path}"
      return false
    end
    
    p "Applying changes to Rails application: #{@path}"
    (@new_app ? start : restart) unless save_config == false
    # todo: check if it went ok before assuming so.
    @new_app = self.dirty = self.valid = false
    
    true
  end
  
  def start
    p "Starting Rails application: #{@path}"
    save_config!
  end
  
  def restart(sender = nil)
    p "Restarting Rails application: #{@path}"
    if @host != @original_values['host'] || @aliases != @original_values['aliases']
      execute('/usr/bin/ruby', CONFIG_UNINSTALLER, [@original_values].to_yaml)
    end
    save_config! if @dirty
    
    tmp_dir = File.join(@path, 'tmp')
    FileUtils.mkdir(tmp_dir) unless File.exist?(tmp_dir)
    Kernel.system("/usr/bin/touch '#{File.join(tmp_dir, 'restart.txt')}'")
  end
  
  def revert(sender = nil)
    @original_values.each do |key, value|
      send "#{key}=", value
    end
    self.valid = self.dirty = self.revertable = false
  end
  
  def reload!
    return if new_app?
    load_data_from_vhost_file
    mark_dirty! if values_changed_after_load?
    set_original_values!
    self.valid = true
  end
  
  def save_config!
    p "Saving configuration: #{config_path}"
    execute '/usr/bin/ruby', CONFIG_INSTALLER, [to_hash].to_yaml
    set_original_values!
  end
  
  def config_path
    File.join(PassengerPaneConfig::PASSENGER_APPS_DIR, "#{@host}.#{PassengerPaneConfig::PASSENGER_APPS_EXTENSION}")
  end
  
  def rbSetValue_forKey(value, key)
    super
    self.revertable = true
    mark_dirty!
    @custom_environment = nil if key == 'environment'
    set_default_host_from_path(@path) if key == 'path' && (@host.nil? || @host.empty?) && (!@path.nil? && !@path.empty?)
    self.valid = (!@host.nil? && !@host.empty? && !@path.nil? && !@path.empty?)
  end
  
  def mark_dirty!
    self.dirty = true
    PrefPanePassenger.sharedInstance.applicationMarkedDirty self
  end
  
  def to_hash
    @user_defined_data = "  <directory \"#{File.join(@path.to_s, 'public')}\">\n    Order allow,deny\n    Allow from all\n  </directory>" if @new_app
    {
      'app_type' => application_type,
      'config_path' => config_path,
      'host' => @host.to_s,
      'aliases' => @aliases.to_s,
      'path' => @path.to_s,
      'environment' => (@environment.nil? ? @custom_environment : (@environment == DEVELOPMENT ? 'development' : 'production')),
      'vhostname' => @vhostname,
      'user_defined_data' => @user_defined_data
    }
  end
  
  private
  
  def check_application_type
    env_file = File.join(@path, 'config', 'environment.rb')
    (File.exist?(env_file) and File.read(env_file) =~ /Rails::Initializer/) ? RAILS : RACK
  end
  
  def load_data_from_vhost_file(file = config_path)
    data = File.read(file).strip
    
    data.gsub!(/\n\s*ServerName\s+(.+)/, '')
    self.host = $1
    
    data.gsub!(/\n\s*ServerAlias\s+(.+)/, '')
    self.aliases = $1 || ''
    
    data.gsub!(/\n\s*DocumentRoot\s+"(.+)\/public"/, '')
    self.path = $1
    
    data.gsub!(/\n\s*(Rails|Rack)Env\s+(\w+)/, '')
    if %w{ development production }.include?($2)
      self.environment = ($2 == 'development' ? DEVELOPMENT : PRODUCTION)
    else
      self.environment = nil
      @custom_environment = $2
    end
    
    data.gsub!(/<VirtualHost\s(.+?)>/, '')
    self.vhostname = $1
    
    data.gsub!(/\s*<\/VirtualHost>\n*/, '').gsub!(/^\n*/, '')
    @user_defined_data = data
  end
  
  def values_changed_after_load?
    @original_values.any? do |key, value|
      # user_defined_data and aliases can be empty
      if %{ user_defined_data aliases }.include?(key) && (value.nil? || value.empty?)
        false
      else
        send(key) != value
      end
    end
  end
  
  def set_original_values!
    @original_values = {
      'host' => @host,
      'aliases' => @aliases,
      'path' => @path,
      'environment' => @custom_environment || @environment,
      'user_defined_data' => @user_defined_data
    }
  end
  
  def set_default_host_from_path(path)
    self.host = "#{File.basename(path).downcase.gsub('_','-')}.local"
  end
end