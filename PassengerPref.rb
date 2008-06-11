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
  
  PASSENGER_CONFIG_INSTALLER = File.expand_path('../passenger_config_installer.rb', __FILE__)
  
  ib_outlet :applicationsController
  kvc_accessor :applications
  
  def mainViewDidLoad
    @applications = [].to_ns
    
    install_passenger! unless passenger_installed?
    
    if is_users_apache_config_setup?
      Dir.glob(File.join(USERS_APACHE_PASSENGER_APPS_DIR, '*.vhost.conf')).each do |app|
        @applicationsController.addObject PassengerApplication.alloc.initWithFile(app)
      end
    else
      setup_users_apache_config! if user_wants_us_to_setup_config?
    end
  end
  
  def remove(sender)
    apps = @applicationsController.selectedObjects
    apps.each { |app| app.remove! }
    @applicationsController.removeObjects apps
  end
  
  def restart(sender)
    p "restart"
  end
  
  def passenger_installed?
    `/usr/bin/gem list passenger`.include? 'passenger'
  end
  
  def install_passenger!
    apple_script "tell application \"Terminal\"\nactivate\ndo script with command \"sudo gem install passenger && sudo /usr/bin/passenger-install-apache2-module\"\nend tell"
    alert = OSX::NSAlert.alloc.init
    alert.informativeText = "Oh noes, the drama! It seems like you haven't installed the Passenger gem yet...\n\nI took the liberty of setting up a terminal for you so that you can install it. Once it's done hit OK to continue."
    alert.runModal
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
  
  def browse(sender = nil)
    panel = NSOpenPanel.openPanel
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    if panel.runModalForTypes([]) == NSOKButton
      @applicationsController.selectedObjects.first.setValue_forKey(panel.filenames.first, 'path')
    end
  end
end
