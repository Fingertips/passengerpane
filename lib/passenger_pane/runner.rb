require 'crock'

module PassengerPane
  class Runner
    def initialize(options)
      @options       = options
      @configuration = PassengerPane::Configuration.auto
    end
    
    def machine_readable?
      @options['machine_readable']
    end
    
    def info
      if machine_readable?
        puts JSON.generate({
          'passenger_module_installed' => @configuration.httpd.passenger_module_installed?,
          'passenger_pane_configured' => @configuration.httpd.passenger_pane_configured?
        })
      else
        puts "Apache directory:          #{@configuration.apache_directory}"
        puts "Passenger installed:       #{@configuration.httpd.passenger_module_installed? ? 'yes' : 'no'}"
        puts "Passenger Pane configured: #{@configuration.httpd.passenger_pane_configured? ? 'yes' : 'no'}"
        puts "Registered hostnames:"
        PassengerPane::DirectoryServices.registered_hosts.each do |host|
          puts "  #{host}"
        end
      end
    end
    
    def configure
      unless @configuration.httpd.passenger_pane_configured?
        @configuration.httpd.configure_passenger
        @configuration.httpd.write
        @configuration.httpd.restart
      end
    end
    
    def add(directory)
      options = @options.dup
      options[:path] = File.expand_path(directory)
      application = PassengerPane::Application.new(@configuration, options)
      if application.save
        @configuration.httpd.restart
      end
      if machine_readable?
        puts JSON.generate(application.to_hash)
      end
    end
    
    def update(host)
      if application = PassengerPane::Application.find(@configuration, :host => host)
        application.set(@options)
        if application.save
          @configuration.httpd.restart
        end
        if machine_readable?
          puts JSON.generate(application.to_hash)
        end
      end
    end
    
    def delete(host)
      if application = PassengerPane::Application.find(@configuration, :host => host)
        application.delete
        @configuration.httpd.restart
      end
    end
    
    def list
      if machine_readable?
        puts JSON.generate(@configuration.applications.map do |app|
          app.to_hash
        end)
      else
        @configuration.applications.each_with_index do |app, index|
          puts unless index == 0
          puts "#{app.host}"
          puts "  Aliases:     #{app.aliases}"
          puts "  Folder:      #{app.path}"
          puts "  Environment: #{app.environment}"
        end
      end
    end
    
    def restart(host)
      if host
        if application = PassengerPane::Application.find(@configuration, :host => host)
          application.restart
        else
          $stderr.puts("[!] Can't find application with hostname `#{host}'")
        end
      else
        @configuration.httpd.restart
      end
    end
    
    def register
      @configuration.applications.each do |app|
        app.register
      end
    end
    
    def self.usage
      puts "Usage: #{File.basename($0)} <command> [options] [attributes]"
      puts
      puts "Commands:"
      puts "  list             List all configured applications"
      puts "  register         Register all configured hostnames with Directory Services*"
      puts "  info             Show information about the system"
      puts "  configure        Configure Apache for use with the Passenger Pane*"
      puts "  add <directory>  Add an application in a directory*"
      puts "  update <host>    Update attributes of an application*"
      puts "  delete <host>    Delete an application*"
      puts "  restart <host>   Restart an application"
      puts "  restart          Restart Apache to pick up configuration changes*"
      puts
      puts "* requires root privileges"
      puts
      puts "Options:"
      puts "  -h, --help       Show this help text"
      puts "  -m, --machine    Use machine readable output (YAML)"
      puts
      puts "Attributes:"
      puts "  --host           Hostname for the application (ie. myapp.local)"
      puts "  --aliases        Aliases for the application (ie. assets.myapp.local)"
      puts "  --path           The folder with the application"
      puts "  --environment    The environment to run, usually development or production"
      puts "  --framework      The framework, either rack or rails"
    end
    
    def self.run(flags, args)
      options = {}
      command = args.shift.to_s
      
      return usage if command == ''
      
      flags.each do |name, value|
        case name
        when 'h', 'help'
          command = 'help'
        when 'm', 'machine'
          options['machine_readable'] = true
        else
          options[name] = value
        end
      end
      
      case command
      when 'info'
        new(options).info
      when 'configure'
        new(options).configure
      when 'add'
        new(options).add(args.first)
      when 'update'
        new(options).update(args.first)
      when 'delete'
        new(options).delete(args.first)
      when 'restart'
        new(options).restart(args.first)
      when 'list'
        new(options).list
      when 'register'
        new(options).register
      else
        path = trust(File.expand_path(command))
        if File.exist?(path)
          new(options).add(path)
        else
          usage
        end
      end
    end
  end
end
