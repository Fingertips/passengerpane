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

require File.expand_path('../shared_passenger_behaviour', __FILE__)
require File.expand_path('../PassengerApplication', __FILE__)

class PrefPanePassenger < NSPreferencePane
  include SharedPassengerBehaviour
  
  USERS_APACHE_CONFIG = "/etc/apache2/users/#{OSX.NSUserName}.conf"
  PASSENGER_CONFIG_INSTALLER = File.expand_path('../passenger_config_installer.rb', __FILE__)
  
  ib_outlet :applicationsController
  kvc_accessor :applications
  
  def mainViewDidLoad
    @applications = [].to_ns
    
    if is_users_apache_config_setup?
      Dir.glob("/etc/apache2/users/passenger_apps/*.vhost.conf").each do |app|
        @applicationsController.addObject PassengerApplication.alloc.initWithFile(app)
      end
    else
      setup_users_apache_config! if user_wants_us_to_setup_config?
    end
  end
  
  # "It seems that your apache configuration hasn't been supercharged with Passenger deploy-dull-making power yet, would you like to do this now?"
  
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
    conf = File.read(USERS_APACHE_CONFIG)
    USERS_APACHE_CONFIG_LOAD_PASSENGER.all? { |line| conf.include? line }
  end
  
  def user_wants_us_to_setup_config?
    alert = OSX::NSAlert.alloc.init
    alert.informativeText = "It seems that your apache configuration hasn't been supercharged with Passenger deploy-dull-making power yet, would you like to do this now?"
    alert.addButtonWithTitle('Cancel')
    alert.addButtonWithTitle('OK')
    alert.runModal == OSX::NSAlertSecondButtonReturn
  end
  
  def setup_users_apache_config!
    execute "/usr/bin/env ruby '#{PASSENGER_CONFIG_INSTALLER}' '#{USERS_APACHE_CONFIG}'"
  end
end
