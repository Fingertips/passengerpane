#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>

@interface PassengerPref : NSPreferencePane
{
  Boolean authorized;
  NSMutableArray *applications;
  
  IBOutlet NSColor *textStateColor;
  
  IBOutlet NSArrayController *applicationsController;
}

- (Boolean)isDirty;

@end