#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import "CLI.h"

@interface PassengerPref : NSPreferencePane
{
  BOOL authorized, dirty, passengerModuleInstalled;
  
  NSMutableArray *applications;
  
  IBOutlet NSColor *textStateColor;
  
  IBOutlet NSView *mainView;
  IBOutlet NSArrayController *applicationsController;
  IBOutlet NSImageView *passengerIconView;
  IBOutlet NSButton *openInBrowserButton;
  IBOutlet SFAuthorizationView *authorizationView;
  IBOutlet NSTableView *applicationsTableView;
  IBOutlet NSView *passengerModuleWarning;
}

@property (assign, getter=isAuthorized) BOOL authorized;
@property (assign, getter=isDirty) BOOL dirty;
@property (assign, getter=isPassengerModuleInstalled) BOOL passengerModuleInstalled;

@property (assign) NSMutableArray *applications;
@property (assign) NSColor *textStateColor;

- (void) setupUI;
- (void) setupAuthorizationView;
- (void) setupApplicationView;
- (void) setupPassengerModuleWarning;

- (IBAction) add:(id)sender;
- (IBAction) remove:(id)sender;
- (IBAction) browse:(id)sender;

- (IBAction) apply:(id)sender;
- (IBAction) revert:(id)sender;
- (IBAction) restart:(id)sender;

- (IBAction) openAddressInBrowser:(id)sender;
- (IBAction) showPassengerHelp:(id)sender;

- (void) paneWillBecomeActive:(id)sender;

- (void) loadApplications;
- (void) reloadApplications;

- (Application *) selectedApplication;
- (NSString *) pathForDirectoryBrowser;

- (BOOL) requestAuthorization;

- (void) checkForDirtyApplications;
- (void) checkIfPassengerModuleInstalled;

@end