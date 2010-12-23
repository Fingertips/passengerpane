#import "PassengerPref.h"

@implementation PassengerPref

@synthesize authorized, dirty;

@synthesize applications;
@synthesize textStateColor;

- (void) mainViewDidLoad {
  CLI *cli = [CLI sharedInstance];
  [cli setPathToCLI:[[self bundle] pathForResource:@"ppane" ofType:nil inDirectory:@"bin"]];
  [cli setAppDelegate:self];
  
  [self setupUI];
  [self setupAuthorizationView];
  [self setupApplicationView];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(paneWillBecomeActive:)
                                               name:NSApplicationWillBecomeActiveNotification
                                             object:NULL];
}

- (void)setupUI {
  NSImage *browserButtonImage;

  [passengerIconView setImage:[[NSImage alloc] initByReferencingFile:[[self bundle] pathForImageResource:@"label"]]];
  browserButtonImage = [[NSImage alloc] initByReferencingFile:[[self bundle] pathForImageResource:@"OpenInBrowserTemplate"]];
  [browserButtonImage setTemplate:YES];
  [openInBrowserButton setImage:browserButtonImage];
  
  [self setTextStateColor:NSColor.disabledControlTextColor];
}

- (void)setupAuthorizationView {
  self.authorized = NO;
  [authorizationView setString:kAuthorizationRightExecute];
  [authorizationView setDelegate:self];
  [authorizationView setAutoupdate:YES];
  [authorizationView updateStatus:self];
}

- (void)setupApplicationView {
//  [applicationsTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
//  [applicationsTableView setDraggingSourceOperationMask:NSDragOperationGeneric forLocal:NO];
  [self loadApplications];
  [applicationsController setSelectedObjects:[NSArray arrayWithObjects:[applications objectAtIndex:0], nil]];
}

#pragma SFAuthorizationView delegate methods

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
  [self setTextStateColor:NSColor.blackColor];
  [[CLI sharedInstance] setAuthorizationRef:[[view authorization] authorizationRef]];
  self.authorized = YES;
  NSLog(@"Pane is now authorized");
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)authorizationView {
  [self setTextStateColor:NSColor.disabledControlTextColor];
  [[CLI sharedInstance] deauthorize];
  self.authorized = NO;
  NSLog(@"Pane is now deauthorized");
}

#pragma NSTableViewDataSource protocol methods

#pragma KeyValueObserving protocol methods

- (void)didChangeValueForKey:(NSString *)key {
  [super didChangeValueForKey:key];
  if (key == @"dirty") {
    [self checkForDirtyApplications];
  }
}

#pragma Notifications

- (void)paneWillBecomeActive:(id)sender {
  [self loadApplications];
}

#pragma Actions

- (void)remove:(id)sender {}
- (void)browse:(id)sender {}

- (void)apply:(id)sender {
  Application *application;
  BOOL isChanged = NO;
  
  if ([self requestAuthorization]) {
    for (application in applications) {
      if ([application isDirty]) {
        NSLog(@"Found dirty application: %@", application.host);
        [[CLI sharedInstance] update:application];
        isChanged = YES;
      }
    }
    if (isChanged) {
      [[CLI sharedInstance] restart];
    }
  } else {
    NSLog(@"Unable to apply because authorization failed.");
  }
}
- (void)revert:(id)sender {}

- (void)restart:(id)sender {
  Application *application = [[applicationsController selectedObjects] objectAtIndex:0];
  [[CLI sharedInstance] restart:application];
}

- (void)openAddressInBrowser:(id)sender {}
- (void)showPassengerHelp:(id)sender {}

#pragma Properties

- (void)loadApplications {
  [self setApplications:[[CLI sharedInstance] listApplications]];
}

- (BOOL)requestAuthorization {
  NSError *error;
  if ([[authorizationView authorization] obtainWithRight:kAuthorizationRightExecute
                                               flags:(kAuthorizationFlagPreAuthorize ||
                                                      kAuthorizationFlagExtendRights ||
                                                      kAuthorizationFlagInteractionAllowed)
                                               error:&error]
      ) {
    [self authorizationViewDidAuthorize:authorizationView];
    return YES;
  } else {
    return NO;
  }
}

- (void)checkForDirtyApplications {
  Application *application;
  for (application in applications) {
    if ([application isDirty]) {
      [self setDirty:YES];
      return;
    }
  }
  [self setDirty:NO];
}

@end