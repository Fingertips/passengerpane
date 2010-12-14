#import "PassengerPref.h"

@implementation PassengerPref

- (void) mainViewDidLoad {
  [self setupUI];
  [self setupAuthorizationView];
  [self setupApplicationView];
}

- (void)setupUI {
  NSImage *browserButtonImage;

  [passengerIconView setImage:[[NSImage alloc] initByReferencingFile:[[self bundle] pathForImageResource:@"label"]]];
  browserButtonImage = [[NSImage alloc] initByReferencingFile:[[self bundle] pathForImageResource:@"OpenInBrowserTemplate"]];
  [browserButtonImage setTemplate:true];
  [openInBrowserButton setImage:browserButtonImage];
  
  textStateColor = NSColor.disabledControlTextColor;
}

- (void)setupAuthorizationView {
  authorized = false;
  [authorizationView setString:kAuthorizationRightExecute];
  [authorizationView setDelegate:self];
  [authorizationView setAutoupdate:true];
  [authorizationView updateStatus:self];
}

- (void)setupApplicationView {
  applications = [NSMutableArray array];
}


- (Boolean)isDirty {
  return false;
}

@end