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

	def mainViewDidLoad
		NSLog("Passenger PreferencePane loaded")
	end
	
end
