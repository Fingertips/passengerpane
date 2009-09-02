#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
 
@interface HelpHelper : NSObject
{
}
// In 10.6 the NSHelpManager#registerBooksInBundle method was added. This
// method does the same, but for 10.5 as well.
+(void)registerBooksInBundle:(NSBundle *)bundle;
@end