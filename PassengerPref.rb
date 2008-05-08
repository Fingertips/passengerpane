#
#  PassengerPref.m
#  Passenger
#
#  Created by eloy on 5/8/08.
#  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'

include OSX

class PrefPanePassenger < NSPreferencePane
  kvc_accessor :applications
  
  def mainViewDidLoad
    @applications = [{ 'host' => 'example.local', 'path' => '/some/path/to/app' }]
    p @applications
  end
  
  def add(sender)
    p "add"
  end
  
  def remove(sender)
    p "remove"
  end
  
  def restart(sender)
    p "restart"
  end
  
  private
  
  def p(obj)
    NSLog(obj.inspect)
  end
end
