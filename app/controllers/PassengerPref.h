#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import "CLI.h"

@interface PassengerPref : NSPreferencePane
{
  BOOL authorized, dirty;
  NSMutableArray *applications;
  
  IBOutlet NSColor *textStateColor;
  
  IBOutlet NSView *mainView;
  IBOutlet NSArrayController *applicationsController;
  IBOutlet NSImageView *passengerIconView;
  IBOutlet NSButton *openInBrowserButton;
  IBOutlet SFAuthorizationView *authorizationView;
  IBOutlet NSTableView *applicationsTableView;
}

@property (assign, getter=isAuthorized) BOOL authorized;
@property (assign, getter=isDirty) BOOL dirty;

@property (retain) NSMutableArray *applications;
@property (retain) NSColor *textStateColor;

- (void) setupUI;
- (void) setupAuthorizationView;
- (void) setupApplicationView;

- (void) remove:(id)sender;
- (void) browse:(id)sender;

- (void) apply:(id)sender;
- (void) revert:(id)sender;
- (void) restart:(id)sender;

- (void) openAddressInBrowser:(id)sender;
- (void) showPassengerHelp:(id)sender;

- (void) paneWillBecomeActive:(id)sender;

- (void) loadApplications;
- (void) reloadApplications;

- (Application *) selectedApplication;
- (NSString *) pathForDirectoryBrowser;

- (BOOL) requestAuthorization;

- (void) checkForDirtyApplications;

@end