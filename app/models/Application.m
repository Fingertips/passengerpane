#import "Application.h"


@implementation Application

@synthesize host, aliases, path, framework, environment, vhostAddress, userDefinedData;
@synthesize dirty, valid;

- (id) init {
  if ((self = [super init])) {
    self.host = @"";
    self.aliases = @"";
    self.path = @"";
    self.framework = @"rails";
    self.environment = @"development";
    self.vhostAddress = @"*:80";
    self.userDefinedData = @"";
    self.dirty = NO;
    [self validate];
  }
  return self;
}

- (id) initWithDictionary:(NSDictionary*)dictionary {
  if ((self = [self init])) {
    self.host = [dictionary objectForKey:@"host"];
    self.aliases = [dictionary objectForKey:@"aliases"];
    self.path = [dictionary objectForKey:@"path"];
    self.framework = [dictionary objectForKey:@"framework"];
    self.environment = [dictionary objectForKey:@"environment"];
    self.vhostAddress = [dictionary objectForKey:@"vhost_address"];
    self.userDefinedData = [dictionary objectForKey:@"user_defined_data"];
    self.dirty = NO;
    [self validate];
  }
  return self;
}

- (void) setValue:(id)value forKey:(NSString*)key {
  [super setValue:value forKey:key];
  [self validate];
}

- (void) validate {
  self.valid = !(IsEmpty(host)||IsEmpty(path));
}

@end
