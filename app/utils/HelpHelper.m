#import "HelpHelper.h"
 
@implementation HelpHelper
 
+(void)registerBooksInBundle:(NSBundle *)bundle {
  OSStatus err;
  FSRef fsref;
  
  err = FSPathMakeRef((const UInt8 *)[[bundle bundlePath] UTF8String], &fsref, NULL);
  if (err != noErr) {
    NSLog(@"Could not get path for bundle - Passenger.prefPane.\n");
    return;
  }
  
  err = AHRegisterHelpBook(&fsref);
  if (err != noErr) {
    NSLog(@"Could register Apple Help for Passenger.prefPane.\n");
  }
}
 
@end