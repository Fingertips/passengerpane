//
//  PassengerPref.m
//  Passenger
//
//  Created by eloy on 5/8/08.
//  Copyright (c) 2008 Fingertips. All rights reserved.
//

@interface PassengerLoader : NSObject
{}
@end
@implementation PassengerLoader
@end

static void __attribute__((constructor)) loadRubyPrefPane(void)
{
	RBBundleInit("PassengerPref.rb", [PassengerLoader class], nil);
}
