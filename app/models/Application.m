#import "Application.h"


@implementation Application

@synthesize host, aliases, path, environment, framework;
@synthesize dirty, valid;

- (id) initWithDictionary:(NSDictionary*)dictionary {
  // NSLog(@"Initializing an Application with: %@", dictionary);
  if ((self = [self init])) {
    self.host = [dictionary objectForKey:@"host"];
    self.aliases = [dictionary objectForKey:@"aliases"];
  }
  return self;
}

@end
