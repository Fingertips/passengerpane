#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface HelpHelper : NSObject
{
}
+(void)openHelpPage:(CFStringRef) pagePath;
@end