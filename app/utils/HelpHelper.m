#import "HelpHelper.h"

@implementation HelpHelper

+(void)openHelpPage:(CFStringRef) pagePath {
  AHGotoPage(NULL, pagePath, NULL);
}

@end