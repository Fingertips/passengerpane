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

require File.expand_path('../PassengerApplication', __FILE__)

class PrefPanePassenger < NSPreferencePane
  ib_outlet :applicationsController
  kvc_accessor :applications
  
  def mainViewDidLoad
    @applications = [].to_ns
    
    if is_users_apache_config_setup?
      Dir.glob("/etc/apache2/users/passenger_apps/*.vhost.conf").each do |app|
        @applicationsController.addObject PassengerApplication.alloc.initWithFile(app)
      end
    else
      setup_users_apache_config!
    end
  end
  
  # "It seems that your apache configuration hasn't been supercharged with Passenger power, would you like to do this now?"
  
  # def add(sender)
  #   p "add"
  # end
  
  def remove(sender)
    apps = @applicationsController.selectedObjects
    apps.each { |app| app.remove! }
    @applicationsController.removeObjects apps
  end
  
  def restart(sender)
    p "restart"
  end
  
  USERS_APACHE_CONFIG_LOAD_PASSENGER = [
    'LoadModule passenger_module /Library/Ruby/Gems/1.8/gems/passenger-1.0.1/ext/apache2/mod_passenger.so',
    'RailsSpawnServer /Library/Ruby/Gems/1.8/gems/passenger-1.0.1/bin/passenger-spawn-server',
    'RailsRuby /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby',
    'RailsEnv development'
  ]

  def is_users_apache_config_setup?
    conf = File.read("/etc/apache2/users/#{OSX.NSUserName}.conf")
    USERS_APACHE_CONFIG_LOAD_PASSENGER.all? { |line| conf.include? line }
  end
  
  private
  
  def p(obj)
    NSLog(obj.inspect)
  end
end
