#import "CLI.h"

@implementation CLI

static id sharedCLI = nil;

+ (id)sharedInstance{
  if (sharedCLI == nil) {
    sharedCLI = [[CLI alloc] init];
  }
  return sharedCLI;
}

@synthesize pathToCLI;

- (id)init {
  if ((self = [super init])) {
    authorizationRef = NULL;
  }
  return self;
}

- (NSMutableArray *)listApplications {
  id result;
  NSDictionary *item;
  NSEnumerator *enumerator;
  NSMutableArray *applications;
  
  result = [self execute:[NSArray arrayWithObjects:@"list", @"-m", nil] elevated:NO];
  applications = [[NSMutableArray arrayWithCapacity:[result count]] autorelease];
  
  enumerator = [result objectEnumerator];
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  while (item = [enumerator nextObject]) {
    [applications addObject:[[[Application alloc] initWithDictionary:item] autorelease]];
  }
  [pool drain];
  
  return applications;
}

- (id)execute:(NSArray *)arguments elevated:(BOOL)elevated {
  if (elevated) {
    return [NSDictionary dictionary];
  } else {
    return [self execute:arguments];
  }
}

- (id)execute:(NSArray *)arguments {
  NSString *data;
  NSPipe *stdout = [NSPipe pipe];
  NSTask *ppane;
  
  ppane = [[[NSTask alloc] init] autorelease];
  [ppane setLaunchPath:pathToCLI];
  [ppane setArguments:arguments];
  [ppane setStandardOutput:[stdout fileHandleForWriting]];
  [ppane launch];
  [ppane waitUntilExit];
  
  if ([ppane terminationStatus] == PPANE_SUCCESS) {
    data = [[NSString alloc] initWithData:[[stdout fileHandleForReading] availableData] encoding:NSUTF8StringEncoding];
    [data autorelease];
    return yaml_parse(data);
  } else {
    return [[NSDictionary dictionary] autorelease];
  }
}

// Inspired by: http://svn.kismac-ng.org/kmng/trunk/Subprojects/BIGeneric/BLAuthentication.m
- (BOOL)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments {
  char** args;
  OSStatus err = 0;
  unsigned int i = 0;
  
  if (arguments == nil || [arguments count] < 1) { 
    err = AuthorizationExecuteWithPrivileges(authorizationRef, (char *)pathToCommand, 0, NULL, NULL);
  } else  {
    args = malloc(sizeof(char*) * [arguments count]);
    while(i < [arguments count] && i < 19) {
      args[i] = (char*)[[arguments objectAtIndex:i] UTF8String];
      i++;
    }
    args[i] = NULL;
    err = AuthorizationExecuteWithPrivileges(authorizationRef, (char *)pathToCommand, 0, args, NULL);
    free(args);
  }
  
  if (err != 0)  {
    NSBeep();
    NSLog(@"Error %d in AuthorizationExecuteWithPrivileges",err);
    return NO;
  } else  {
    return YES;
  }
}

- (AuthorizationRef) authorizationRef {
  return authorizationRef;
}

- (void) setAuthorizationRef:(AuthorizationRef)ref {
  authorizationRef = ref;
}

-(void)deauthorize {
  authorizationRef = NULL;
}

-(BOOL)isAuthorized {
  if (authorizationRef == NULL) {
    return NO;
  } else  {
    return YES;
  }
}


@end
