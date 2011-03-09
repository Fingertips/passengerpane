module PassengerPane
  class HttpdConf
    attr_accessor :filename
    
    def initialize(configuration)
      @configuration = configuration
      @filename      = File.expand_path(configuration.httpd_conf, configuration.apache_directory)
    end
    
    def contents
      @contents ||= File.read(@filename)
    end
    
    attr_writer :contents
    
    def passenger_vhost_include
      "Include #{@configuration.apache_directory}/#{@configuration.passenger_vhosts}/*.#{@configuration.passenger_vhosts_ext}"
    end
    
    def passenger_configuration_snippet
      %{
# Added by the Passenger preference pane
# Make sure to include the Passenger configuration (the LoadModule,
# PassengerRoot, and PassengerRuby directives) before this section.
<IfModule passenger_module>
  NameVirtualHost *:80
  <VirtualHost *:80>
    ServerName _default_
  </VirtualHost>
  #{passenger_vhost_include}
</IfModule>
      }.strip
    end
    
    def valid?
      `#{@configuration.httpd_binary} -t 2>&1`.strip.end_with?('Syntax OK')
    end
    
    def restart
      if valid?
        system @configuration.apache_restart_command
      else
        $stderr.puts "[!] Apache configuration is not valid, skipping Apache restart"
      end
    end
    
    def passenger_module_installed?
      `#{@configuration.httpd_binary} -D DUMP_MODULES 2>&1`.include? 'passenger_module'
    end
    
    def passenger_pane_configured?
      !!(contents =~ /Include.*#{@configuration.passenger_vhosts}/)
    end
    
    def configure_passenger
      self.contents << "\n\n"
      self.contents << passenger_configuration_snippet
    end
    
    def write
      File.open(@filename, 'w') do |file|
        file.write(contents)
      end
    end
  end
end