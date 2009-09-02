#import "HelpHelper.h"
 
@implementation HelpHelper
 
+(void)registerBooksInBundle:(NSBundle *)bundle {
  // NSString *bundlePath = [bundle bundlePath];
  const void *bundlePath = [[bundle bundlePath] UTF8String];
  
  OSStatus err;
  FSRef fsref;
  
  err = FSPathMakeRef(bundlePath, &fsref, NULL);
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