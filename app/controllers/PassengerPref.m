#import "PassengerPref.h"

@implementation PassengerPref

- (void) mainViewDidLoad {
  [[CLI sharedInstance] setPathToCLI:[[self bundle] pathForResource:@"ppane" ofType:nil inDirectory:@"bin"]];
  [self setupUI];
  [self setupAuthorizationView];
  [self setupApplicationView];
}

@synthesize applications;

- (void)setupUI {
  NSImage *browserButtonImage;

  [passengerIconView setImage:[[NSImage alloc] initByReferencingFile:[[self bundle] pathForImageResource:@"label"]]];
  browserButtonImage = [[NSImage alloc] initByReferencingFile:[[self bundle] pathForImageResource:@"OpenInBrowserTemplate"]];
  [browserButtonImage setTemplate:YES];
  [openInBrowserButton setImage:browserButtonImage];
  
  textStateColor = NSColor.disabledControlTextColor;
}

- (void)setupAuthorizationView {
  authorized = NO;
  [authorizationView setString:kAuthorizationRightExecute];
  [authorizationView setDelegate:self];
  [authorizationView setAutoupdate:YES];
  [authorizationView updateStatus:self];
}

- (void)setupApplicationView {
//  [applicationsTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
//  [applicationsTableView setDraggingSourceOperationMask:NSDragOperationGeneric forLocal:NO];
  [self setApplications:[[CLI sharedInstance] listApplications]];
  [applicationsController setSelectedObjects:[NSArray arrayWithObjects:[applications objectAtIndex:0], nil]];
}

#pragma NSTableViewDataSource protocol methods

#pragma actions and notifications

- (void)remove:(id)sender {}
- (void)browse:(id)sender {}

- (void)apply:(id)sender {}
- (void)revert:(id)sender {}
- (void)restart:(id)sender {}

- (void)openAddressInBrowser:(id)sender {}
- (void)showPassengerHelp:(id)sender {}


- (BOOL)isDirty {
  return NO;
}

@end