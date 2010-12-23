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

- (void) setupUI {
  NSImage *browserButtonImage;

  [passengerIconView setImage:[[NSImage alloc] initByReferencingFile:[[self bundle] pathForImageResource:@"label"]]];
  browserButtonImage = [[NSImage alloc] initByReferencingFile:[[self bundle] pathForImageResource:@"OpenInBrowserTemplate"]];
  [browserButtonImage setTemplate:YES];
  [openInBrowserButton setImage:browserButtonImage];
  
  [self setTextStateColor:NSColor.disabledControlTextColor];
}

- (void) setupAuthorizationView {
  self.authorized = NO;
  [authorizationView setString:kAuthorizationRightExecute];
  [authorizationView setDelegate:self];
  [authorizationView setAutoupdate:YES];
  [authorizationView updateStatus:self];
}

- (void) setupApplicationView {
  [self loadApplications];
  [applicationsController setSelectedObjects:[NSArray arrayWithObjects:[applications objectAtIndex:0], nil]];
}

#pragma SFAuthorizationView delegate methods

- (void) authorizationViewDidAuthorize:(SFAuthorizationView *)view {
  [self setTextStateColor:NSColor.blackColor];
  [[CLI sharedInstance] setAuthorizationRef:[[view authorization] authorizationRef]];
  self.authorized = YES;
  NSLog(@"Pane is now authorized");
}

- (void) authorizationViewDidDeauthorize:(SFAuthorizationView *)authorizationView {
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

- (void) paneWillBecomeActive:(id)sender {
  [self reloadApplications];
}

#pragma Actions

- (void) remove:(id)sender {
  Application *application = [self selectedApplication];
  if (![application isFresh]) {
    [[CLI sharedInstance] delete:application];
  }
  [applicationsController removeObject:application];
}

- (void) browse:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setCanChooseDirectories:YES];
  [panel setCanChooseFiles:NO];
  [panel setDirectory:[self pathForDirectoryBrowser]];
  [panel beginSheetModalForWindow:[mainView window] completionHandler:^(NSInteger button) {
    Application *application = [self selectedApplication];
    if (button == NSFileHandlingPanelOKButton) {
      [application setValue:[panel filename] forKey:@"path"];
    } else if (button == NSFileHandlingPanelCancelButton) {
      if ([application isFresh] && ![application isDirty]) {
        [self remove:sender];
      }
    }
  }];
}

- (void) apply:(id)sender {
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
- (void) revert:(id)sender {}

- (void) restart:(id)sender {
  Application *application = [self selectedApplication];
  [[CLI sharedInstance] restart:application];
}

- (void) openAddressInBrowser:(id)sender {
  Application *application = [self selectedApplication];
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", application.host]];
  [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void) showPassengerHelp:(id)sender {}

#pragma Properties

- (void) loadApplications {
  [self setApplications:[[CLI sharedInstance] listApplications]];
}

- (void) reloadApplications {
  NSUInteger index;
  Application *existingApplication, *loadedApplication;
  NSArray *loadedApplications = [[CLI sharedInstance] listApplications];
  for (loadedApplication in loadedApplications) {
    index = [applications indexOfObjectPassingTest:^ BOOL (id object, NSUInteger index, BOOL *stop) {
      return [[object host] isEqualToString:[loadedApplication host]];
    }];
    // Application is already in the list
    if (index != -1) {
      existingApplication = [applications objectAtIndex:index];
      if (![existingApplication isDirty]) {
        [existingApplication updateWithAttributes:[loadedApplication toDictionary]];
        [existingApplication didApplyChanges];
      }
    // Someone added a new applications we didn't know about
    } else {
      [applicationsController addObject:loadedApplication];
    }
  }
}

- (Application *) selectedApplication {
  return [[applicationsController selectedObjects] objectAtIndex:0];
}

- (NSString *) pathForDirectoryBrowser {
  Application *application = [self selectedApplication];
  if (application) {
    return application.path;
  } else {
    return NSHomeDirectory();
  }
}

- (BOOL) requestAuthorization {
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