#import "PassengerPref.h"

@implementation PassengerPref

- (void) mainViewDidLoad {
  [[CLI sharedInstance] setPathToCLI:[[self bundle] pathForResource:@"ppane" ofType:nil inDirectory:@"bin"]];
  [self setupUI];
  [self setupAuthorizationView];
  [self setupApplicationView];
}

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
  applications = [[CLI sharedInstance] listApplications];
  [applicationsController rearrangeObjects];
}

- (BOOL)isDirty {
  return NO;
}

@end