#import "PassengerPref.h"

@implementation PassengerPref

- (void) mainViewDidLoad {
  applications = [[NSMutableArray alloc] init];
  authorized = false;
}

- (Boolean)isDirty {
  return false;
}

@end