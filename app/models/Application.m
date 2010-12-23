#import "Application.h"


@implementation Application

@synthesize delegate;
@synthesize host, aliases, path;
@synthesize environment;
@synthesize dirty, valid, fresh;

- (id) init {
  if ((self = [super init])) {
    environments = [NSArray arrayWithObjects:@"development", @"production", nil];
    
    self.host = @"";
    self.aliases = @"";
    self.path = @"";
    self.environment = PPANE_DEVELOPMENT;
    self.dirty = NO;
    self.fresh = YES;
    [self validate];
    beforeChanges = [self toDictionary];
  }
  return self;
}

- (id) initWithAttributes:(NSDictionary *)attributes {
  if ((self = [self init])) {
    [self updateWithAttributes:attributes];
    self.dirty = NO;
    self.fresh = NO;
    [self validate];
    beforeChanges = [self toDictionary];
  }
  return self;
}

- (void) updateWithAttributes:(NSDictionary *)attributes {
  self.host = [attributes objectForKey:@"host"];
  self.aliases = [attributes objectForKey:@"aliases"];
  self.path = [attributes objectForKey:@"path"];
  self.environment = [environments indexOfObject:[attributes objectForKey:@"environment"]];
}

- (NSMutableDictionary*) toDictionary {
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  
  [data setValue:self.host forKey:@"host"];
  [data setValue:self.aliases forKey:@"aliases"];
  [data setValue:self.path forKey:@"path"];
  [data setValue:[environments objectAtIndex:environment] forKey:@"environment"];
  
  return data;
}

- (NSArray*) toArgumentArray {
  NSMutableArray *arguments = [NSMutableArray array];
  [[self toDictionary] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [arguments addObject:[NSString stringWithFormat:@"-%@", key]];
    [arguments addObject:obj];
  }];
  return arguments;
}

- (void) validate {
  BOOL result = !(IsEmpty(host) || IsEmpty(path));
  if (result != valid) {
    [delegate willChangeValueForKey:@"valid"];
    [self setValid:result];
    [delegate didChangeValueForKey:@"valid"];
  }
}

- (void) checkChanges {
  BOOL result = ![beforeChanges isEqualToDictionary:[self toDictionary]];
  if (result != dirty) {
    [delegate willChangeValueForKey:@"dirty"];
    [self setDirty:result];
    [delegate didChangeValueForKey:@"dirty"];
  }
}

- (void) didApplyChanges {
  beforeChanges = [self toDictionary];
  self.fresh = NO;
  [self checkChanges];
  [self validate];
}

- (void) setPath:(NSString *)newPath {
  if (IsEmpty(host) && !IsEmpty(newPath)) {
    [self setHost:[NSString stringWithFormat:@"%@.local", [[[NSURL URLWithString:newPath] lastPathComponent] lowercaseString]]];
  }
  path = newPath;
}

- (void) setValue:(id)value forKey:(NSString*)key {
  NSLog(@"Changing %@ to %@", key, value);
  [super setValue:value forKey:key];
  [self validate];
  [self checkChanges];
}

@end
