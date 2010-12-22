#import "Application.h"


@implementation Application

@synthesize host, aliases, path;
@synthesize environment;
@synthesize dirty, valid;

- (id) init {
  if ((self = [super init])) {
    environments = [NSArray arrayWithObjects:@"development", @"production", nil];
    
    self.host = @"";
    self.aliases = @"";
    self.path = @"";
    self.environment = PPANE_DEVELOPMENT;
    self.dirty = NO;
    [self validate];
    beforeChanges = [self toDictionary];
  }
  return self;
}

- (id) initWithDictionary:(NSDictionary*)dictionary {
  if ((self = [self init])) {
    self.host = [dictionary objectForKey:@"host"];
    self.aliases = [dictionary objectForKey:@"aliases"];
    self.path = [dictionary objectForKey:@"path"];
    self.environment = [environments indexOfObject:[dictionary objectForKey:@"environment"]];
    self.dirty = NO;
    [self validate];
    beforeChanges = [self toDictionary];
  }
  return self;
}

- (NSMutableDictionary*) toDictionary {
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  
  [data setValue:self.host forKey:@"host"];
  [data setValue:self.aliases forKey:@"aliases"];
  [data setValue:self.path forKey:@"path"];
  [data setValue:[environments objectAtIndex:environment] forKey:@"environment"];
  
  return data;
}

- (void) validate {
  [self setValid:!(IsEmpty(host)||IsEmpty(path))];
}

- (void) checkChanges {
  NSLog(@"%@", [self toDictionary]);
  [self setDirty:![beforeChanges isEqualToDictionary:[self toDictionary]]];
}

- (void) setValue:(id)value forKey:(NSString*)key {
  NSLog(@"Changing %@ to %@", key, value);
  [super setValue:value forKey:key];
  [self validate];
  [self checkChanges];
}

@end
