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
  
  ib_outlet :newApplicationSheet
  ib_outlet :newApplicationPathTextField
  ib_outlet :newApplicationHostTextField
  
  ib_outlet :installPassengerWarning
  
  ib_outlet :applicationsTableView
  ib_outlet :applicationsController
  kvc_accessor :applications
  
  def mainViewDidLoad
    @applications = [].to_ns
    
    @applicationsTableView.dataSource = self
    @applicationsTableView.registerForDraggedTypes [OSX::NSFilenamesPboardType]
    
    if passenger_installed?
      if is_users_apache_config_setup?
        Dir.glob(File.join(USERS_APACHE_PASSENGER_APPS_DIR, '*.vhost.conf')).each do |app|
          @applicationsController.addObject PassengerApplication.alloc.initWithFile(app)
        end
      else
        setup_users_apache_config! if user_wants_us_to_setup_config?
      end
    else
      @installPassengerWarning.hidden = false
    end
  end
  
  def add(sender = nil)
    NSApp.objc_send(
      :beginSheet, @newApplicationSheet,
      :modalForWindow, mainView.window,
      :modalDelegate, nil,
      :didEndSelector, nil,
      :contextInfo, nil
    )
  end
  
  def remove(sender)
    apps = @applicationsController.selectedObjects
    apps.each { |app| app.remove }
    @applicationsController.removeObjects apps
  end
  
  def browse(sender = nil)
    panel = NSOpenPanel.openPanel
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    fill_in_new_application_text_fields_with_file(panel.filenames.first) if panel.runModal == NSOKButton
  end
  
  def addApplicationFromSheet(sender = nil)
    app = PassengerApplication.alloc.init
    app.path = @newApplicationPathTextField.stringValue
    app.host = @newApplicationHostTextField.stringValue
    @applicationsController.addObject app
    app.start
    
    closeNewApplicationSheet
  end
  
  def closeNewApplicationSheet(sender = nil)
    NSApp.endSheet @newApplicationSheet
    @newApplicationSheet.orderOut self
  end
  
  def showInstallPassengerHelpAlert(sender)
    alert = OSX::NSAlert.alloc.init
    alert.messageText = "Install Passenger Gem"
    alert.informativeText = "The Passenger Preference Pane uses the gem command to locate your Passenger installation.\n\nTo install the current release use:\n“$ sudo gem install passenger”\n“$ sudo passenger-install-apache2-module”\n\nAfter installing the Passenger gem, load the Passenger Preference Pane again and we’ll setup your Apache config for you. (You can ignore the instructions about this during the installation process.)"
    alert.runModal
  end
  
  # Applications NSTableView dataSource drag and drop methods
  
  def tableView_validateDrop_proposedRow_proposedDropOperation(tableView, info, row, operation)
    files = info.draggingPasteboard.propertyListForType(OSX::NSFilenamesPboardType)
    if files.length == 1 and File.directory?(files.first)
      OSX::NSDragOperationGeneric
    else
      OSX::NSDragOperationNone
    end
  end
  
  def tableView_acceptDrop_row_dropOperation(tableView, info, row, operation)
    fill_in_new_application_text_fields_with_file info.draggingPasteboard.propertyListForType(OSX::NSFilenamesPboardType).first
    add
  end
  
  private
  
  def fill_in_new_application_text_fields_with_file(file)
    @newApplicationPathTextField.stringValue = file
    @newApplicationHostTextField.stringValue = "#{File.basename(file).downcase}.local"
  end
  
  USERS_APACHE_CONFIG_LOAD_PASSENGER = [
    'LoadModule passenger_module /Library/Ruby/Gems/1.8/gems/passenger-[\d\.]+/ext/apache2/mod_passenger.so',
    'RailsSpawnServer /Library/Ruby/Gems/1.8/gems/passenger-[\d\.]+/bin/passenger-spawn-server',
    'RailsRuby /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby',
    'RailsEnv development'
  ]
  
  def passenger_installed?
    `/usr/bin/gem list passenger`.include? 'passenger'
  end
  
  def is_users_apache_config_setup?
    conf = File.read(USERS_APACHE_CONFIG)
    USERS_APACHE_CONFIG_LOAD_PASSENGER.all? { |regexp| conf.match regexp }
  end
  
  def user_wants_us_to_setup_config?
    alert = OSX::NSAlert.alloc.init
    alert.messageText = "Configure Apache"
    alert.informativeText = "It seems that your Apache configuration hasn’t been supercharged with Passenger deploy-dull-making power yet, would you like to do this now?"
    alert.addButtonWithTitle('OK')
    alert.addButtonWithTitle('Cancel')
    alert.runModal == OSX::NSAlertFirstButtonReturn
  end
  
  def setup_users_apache_config!
    p "Configuring Apache for Passenger. Patching: #{USERS_APACHE_CONFIG}"
    execute "/usr/bin/env ruby '#{PASSENGER_CONFIG_INSTALLER}' '#{USERS_APACHE_CONFIG}'"
  end
end
