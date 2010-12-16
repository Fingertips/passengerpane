#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import "CLI.h"

@interface PassengerPref : NSPreferencePane
{
  BOOL authorized;
  NSArray *applications;
  
  IBOutlet NSColor *textStateColor;
  
  IBOutlet NSArrayController *applicationsController;
  IBOutlet NSImageView *passengerIconView;
  IBOutlet NSButton *openInBrowserButton;
  IBOutlet SFAuthorizationView *authorizationView;
  IBOutlet NSTableView *applicationsTableView;
}

- (void)setupUI;
- (void)setupAuthorizationView;
- (void)setupApplicationView;

- (BOOL)isDirty;

@end