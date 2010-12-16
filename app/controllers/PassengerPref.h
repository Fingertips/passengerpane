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

- (void)remove:(id)sender;
- (void)browse:(id)sender;

- (void)apply:(id)sender;
- (void)revert:(id)sender;
- (void)restart:(id)sender;

- (void)openAddressInBrowser:(id)sender;
- (void)showPassengerHelp:(id)sender;

- (BOOL)isDirty;

@end