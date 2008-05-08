#
#  PassengerPref.m
#  Passenger
#
#  Created by eloy on 5/8/08.
#  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'

include OSX

class PassengerApplication < NSObject
  kvc_accessor :host, :path
  
  def init
    if super_init
      @host, @path = 'foo.local', '/some/path/to/app'
      self
    end
  end
  
  def initWithHost_path(host, path)
    if init
      @host, @path = host, path
      self
    end
  end
  
  def restart(sender)
    p "restart #{self}"
  end
  
  def remove!
    p "remove #{self}"
  end
end

class PrefPanePassenger < NSPreferencePane
  ib_outlet :applicationsController
  kvc_accessor :applications
  
  def mainViewDidLoad
    @applications = [].to_ns
    
    #app = PassengerApplication.alloc.initWithHost_path('foo.local', '/some/path/to/app')
    app = PassengerApplication.alloc.init
    @applicationsController.addObject app
  end
  
  def add(sender)
    p "add"
  end
  
  def remove(sender)
    p "remove"
    apps = @applicationsController.selectedObjects
    p apps
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
