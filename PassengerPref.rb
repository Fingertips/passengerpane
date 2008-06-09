#
#  PassengerPref.m
#  Passenger
#
#  Created by Eloy Duran on 5/8/08.
#  Copyright (c) 2008 Eloy Duran. All rights reserved.
#

require 'osx/cocoa'

include OSX
OSX.require_framework 'PreferencePanes'

class PassengerApplication < NSObject
  CONF_PATH = "/etc/apache2/users/passenger_apps"
  
  kvc_accessor :host, :path
  
  def init
    if super_init
      @host, @path = 'foo.local', '/some/path/to/app'
      self
    end
  end
  
  def initWithFile(file)
    if init
      @host, @path = File.read(file).scan(/ServerName\s+([\w\.]+).+DocumentRoot\s+"([\w\/\s]+)"/m).flatten
      self
    end
  end
  
  def restart(sender)
    p "Restarting Rails application: #{@path}"
    save_config!
  end
  
  def remove!
    p "remove #{self}"
  end
  
  def save_config!
    execute "/usr/bin/env ruby '#{File.expand_path('../config_installer.rb', __FILE__)}' '#{config_file}' '#{@host}' '#{@path}'"
  end
  
  def config_file
    @config_file ||= "#{CONF_PATH}/#{@host}.vhost.conf"
  end
  
  private
  
  def execute(command)
    script = NSAppleScript.alloc.initWithSource("do shell script \"#{command}\" with administrator privileges")
    script.performSelector_withObject("executeAndReturnError:", nil)
  end
end

class PrefPanePassenger < NSPreferencePane
  ib_outlet :applicationsController
  kvc_accessor :applications
  
  def mainViewDidLoad
    @applications = [].to_ns
    Dir.glob("/etc/apache2/users/passenger_apps/*.vhost.conf").each do |app|
      @applicationsController.addObject PassengerApplication.alloc.initWithFile(app)
    end
  end
  
  # def add(sender)
  #   p "add"
  # end
  
  def remove(sender)
    apps = @applicationsController.selectedObjects
    apps.each { |app| app.remove! }
    @applicationsController.removeObjects apps
  end
  
  # def restart(sender)
  #   p "restart"
  # end
  
  private
  
  def p(obj)
    NSLog(obj.inspect)
  end
end
