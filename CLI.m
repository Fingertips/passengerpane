#import "CLI.h"

@implementation CLI

static id sharedCLI = nil;

@synthesize authorizationRef;

+ (id)sharedInstance{
  if (sharedCLI == nil) {
    sharedCLI = [[CLI alloc] init];
  }
  return sharedCLI;
}

- (id)init {
  if ((self = [super init])) {
    authorizationRef = NULL;
  }
  return self;
}

@end
