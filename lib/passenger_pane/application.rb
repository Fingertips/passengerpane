require 'fileutils'

module PassengerPane
  class Application
    RAILS_APP_REGEXP = /::Initializer\.run|Application\.initialize!/
    ATTRIBUTES = [:config_filename, :host, :aliases, :path, :framework, :environment, :vhost_address, :user_defined_data]
    
    def self.glob(configuration)
      File.join(
        configuration.apache_directory,
        configuration.passenger_vhosts,
        "*.#{configuration.passenger_vhosts_ext}"
      )
    end
    
    def self.all(configuration)
      Dir.glob(glob(configuration)).map do |config_filename|
        new(configuration, :config_filename => config_filename)
      end
    end
    
    def self.find(configuration, conditions={})
      if conditions[:host]
        all(configuration).detect do |app|
          app.host == conditions[:host]
        end
      end
    end
    
    attr_accessor(*ATTRIBUTES)
    
    def initialize(configuration, options={})
      @configuration = configuration
      set(options)
      if options[:config_filename]
        @new = false
        _parse
      elsif options[:path]
        @new = true
        _derive
      else
        raise ArgumentError, "Please specify either a :config_filename or :path"
      end
      @before_changes = to_hash
    end
    
    def set(options)
      options.each do |key, value|
        setter = trust("#{key}=")
        send(setter, trust(value)) if respond_to?(setter)
      end
    end
    
    def new?
      @new
    end
    
    # -- Virtual Host reading and writing
    
    def contents
      @contents ||= File.read(trust(@config_filename))
    end
    
    attr_writer :contents
    
    def _parse
      data = contents.dup
      
      data.gsub!(/\n\s*ServerName\s+(.+)/, '')
      @host = $1
      
      data.gsub!(/\n\s*ServerAlias\s+(.+)/, '')
      @aliases = $1 || ''
      
      data.gsub!(/\n\s*DocumentRoot\s+"(.+)"/, '')
      path = $1
      if path.end_with?('public')
        @path = File.dirname(path)
      else
        @path = path
      end
      
      data.gsub!(/\n\s*(Rails|Rack)Env\s+(\w+)/, '')
      @framework   = $1 ? $1.downcase : nil
      @environment = $2
      
      data.gsub!(/<VirtualHost\s(.+?)>/, '')
      @vhost_address = $1
      
      data.gsub!(/\s*<\/VirtualHost>\n*/, '').gsub!(/^\n*/, '')
      @user_defined_data = data.strip
    end
    
    def _document_root
      File.join(@path, 'public')
    end
    
    def _directory_defaults
      %{
  <Directory "#{_document_root}">
    Order allow,deny
    Allow from all
  </Directory>
      }.strip
    end
    
    def _config_filename
      File.join(
        @configuration.apache_directory,
        @configuration.passenger_vhosts,
        "#{@host}.#{@configuration.passenger_vhosts_ext}"
      )
    end
    
    def _framework
      environment_file = File.join(@path, 'config', 'environment.rb')
      if File.exist?(environment_file) and File.read(environment_file) =~ RAILS_APP_REGEXP
        'rails'
      else
        'rack'
      end
    end
    
    def _derive
      @host ||= "#{File.basename(path).downcase.gsub('_','-')}.local"
      @aliases ||= ''
      @environment ||= 'development'
      @vhost_address ||= '*:80'
      @user_defined_data ||= _directory_defaults
      @config_filename ||= _config_filename
      @framework ||= _framework
    end
    
    def rails?; @framework == 'rails' end
    def rack?;  @framework == 'rack'  end
    
    def vhost_snippet
      lines = []
      lines << "<VirtualHost #{vhost_address}>"
      lines << "  ServerName #{host}"
      lines << "  ServerAlias #{aliases}" unless aliases == ''
      lines << "  DocumentRoot \"#{_document_root}\""
      if @framework
        lines << "  #{rails? ? 'RailsEnv' : 'RackEnv'} #{environment}"
      end
      lines << "  #{user_defined_data}" unless user_defined_data.strip == ''
      lines << "</VirtualHost>"
      lines.join("\n")
    end
    
    def write
      FileUtils.mkdir_p(File.dirname(@config_filename))
      File.open(@config_filename, 'w') do |file|
        file.write(vhost_snippet)
      end; true
    end
    
    # -- Dirty checking
    
    def to_hash
      hash = { 'hosts' => [host, *aliases.split] }
      ATTRIBUTES.each do |key|
        hash[key.to_s] = instance_variable_get("@#{key}")
      end; hash
    end
    
    def changed?
      @before_changes != to_hash
    end
    
    def added_hosts
      to_hash['hosts'] - @before_changes['hosts']
    end
    
    def removed_hosts
      @before_changes['hosts'] - to_hash['hosts']
    end
    
    # -- Directory services
    
    def register
      PassengerPane::DirectoryServices.register(to_hash['hosts'])
    end
    
    def unregister
      PassengerPane::DirectoryServices.unregister(to_hash['hosts'])
    end
    
    def sync_host_registration
      if new?
        register
      else
        PassengerPane::DirectoryServices.register(added_hosts) and
        PassengerPane::DirectoryServices.unregister(removed_hosts)
      end
    end
    
    # -- Persisting
    
    def save
      write and sync_host_registration
    end
    
    def delete
      FileUtils.rm_rf(config_filename)
      unregister
      true
    end
    
    # -- Operational
    
    def restart
      if File.exist?(@path)
        FileUtils.mkdir_p(File.join(File.join(@path, 'tmp')))
        FileUtils.touch(File.join(@path, 'tmp', 'restart.txt'))
      end
    end
  end
end