module PassengerPane
  class Configuration
    CONFIG_FILENAME  = '~/.passenger_pane.yml'
    APACHE_DIRECTORY = '/private/etc/apache2'
    
    def self.defaults
      {
        :ruby_binary            => "/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby",
        :httpd_binary           => "/usr/sbin/httpd",
        :httpd_conf             => "httpd.conf",
        :passenger_vhosts       => "passenger_pane_vhosts",
        :passenger_vhosts_ext   => "vhost.conf",
        :apache_restart_command => "/usr/sbin/httpd -k graceful"
      }
    end
    
    def self.config_filename
      File.expand_path(CONFIG_FILENAME)
    end
    
    def self.auto
      configuration = new
      if File.exist?(trust(config_filename))
        configuration.set(YAML.load_file(config_filename))
      end
      configuration
    end
    
    attr_accessor :apache_directory, *defaults.keys
    
    def initialize(apache_directory=APACHE_DIRECTORY)
      self.apache_directory = apache_directory
      set(self.class.defaults)
    end
    
    def set(options)
      options.each do |key, value|
        begin
          send("#{key}=", value)
        rescue NoMethodError
          raise ArgumentError, "There is no configuration named `#{key}', valid options are: #{self.class.defaults.keys.join(', ')} and apache_directory."
        end
      end
    end
    
    def httpd
      @httpd ||= PassengerPane::HttpdConf.new(self)
    end
    
    def applications
      PassengerPane::Application.all(self)
    end
  end
end
