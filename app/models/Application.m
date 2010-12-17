#import "Application.h"


@implementation Application

@synthesize host, aliases, path, environment, framework;
@synthesize dirty, valid;

- (id) initWithDictionary:(NSDictionary*)dictionary {
  if ((self = [self init])) {
    self.host = [dictionary objectForKey:@"host"];
    self.aliases = [dictionary objectForKey:@"aliases"];
    self.path = [dictionary objectForKey:@"path"];
    self.environment = [dictionary objectForKey:@"environment"];
    self.framework = [dictionary objectForKey:@"framework"];
    self.dirty = NO;
    self.valid = YES;
  }
  return self;
}

@end
