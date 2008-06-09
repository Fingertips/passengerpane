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
  
  def restart(sender)
    p "restart"
  end
  
  private
  
  def p(obj)
    NSLog(obj.inspect)
  end
end
