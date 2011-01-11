#import "Application.h"

static NSArray *environments;

@implementation Application

@synthesize delegate;
@synthesize host, aliases, path, configFilename;
@synthesize environment;
@synthesize dirty, valid, fresh;
@synthesize beforeChanges;

+(void) initialize {
  if (!environments)
    environments = [NSArray arrayWithObjects:@"development", @"production", nil];
    [environments retain];
}

- (id) init {
  if (self = [super init]) {
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
  if (self = [self init]) {
    [self updateAttributes:attributes];
    self.dirty = NO;
    self.fresh = NO;
    [self validate];
    beforeChanges = [self toDictionary];
  }
  return self;
}

- (id) initWithDirectory:(NSString *)aPath {
  if (self = [self init]) {
    beforeChanges = [self toDictionary];
    self.path = aPath;
    self.dirty = YES;
    self.fresh = YES;
    [self validate];
  }
  return self;
}

- (void) updateAttributes:(NSDictionary *)attributes {
  NSString *environmentAsString = [attributes objectForKey:@"environment"];
  self.host = [attributes objectForKey:@"host"];
  self.aliases = [attributes objectForKey:@"aliases"];
  self.path = [attributes objectForKey:@"path"];
  if (environmentAsString) {
    self.environment = [environments indexOfObject:environmentAsString];
  } else {
    self.environment = 0;
  }
  self.configFilename = [attributes objectForKey:@"config_filename"];
}

- (NSMutableDictionary*) toDictionary {
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  [data setValue:self.host forKey:@"host"];
  [data setValue:self.aliases forKey:@"aliases"];
  [data setValue:self.path forKey:@"path"];
  if (environment) {
    [data setValue:[environments objectAtIndex:environment] forKey:@"environment"];
  } else {
    [data setValue:[environments objectAtIndex:0] forKey:@"environment"];
  }
  [data setValue:self.configFilename forKey:@"config_filename"];
  
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

- (void) revert {
  [self updateAttributes:beforeChanges];
  [self validate];
  [self checkChanges];
}

- (void) setPath:(NSString *)newPath {
  if (IsEmpty(host) && !IsEmpty(newPath)) {
    [self setHost:[NSString stringWithFormat:@"%@.local", [[[NSURL URLWithString:newPath] lastPathComponent] lowercaseString]]];
  }
  path = newPath;
}

- (void) setValue:(id)value forKey:(NSString*)key {
  [super setValue:value forKey:key];
  [self validate];
  [self checkChanges];
}

@end
