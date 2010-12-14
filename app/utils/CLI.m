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

- (NSArray *)listApplications {
  NSArray *applications;
  
  [self executeCommand:pathToCLI withArgs:[NSArray arrayWithObjects:@"list", @"-m", nil]];
  
  return applications;
}

- (Boolean)execute:(NSArray *)arguments {
  return false;
}

- (Boolean)execute:(NSArray *)arguments secure:(Boolean)secure {
  
  if (secure) {
    
  } else {
    [self execute:arguments];
  }
  return false;
}

// Inspired by: http://svn.kismac-ng.org/kmng/trunk/Subprojects/BIGeneric/BLAuthentication.m
- (Boolean)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments {
  char** args;
  OSStatus err = 0;
  unsigned int i = 0;
  
  if (arguments == nil || [arguments count] < 1) { 
    err = AuthorizationExecuteWithPrivileges(authorizationRef,
                                             (char *)pathToCommand,
                                             0,
                                             NULL,
                                             NULL);
  } else  {
    args = malloc(sizeof(char*) * [arguments count]);
    while(i < [arguments count] && i < 19) {
      args[i] = (char*)[[arguments objectAtIndex:i] UTF8String];
      i++;
    }
    args[i] = NULL;
    err = AuthorizationExecuteWithPrivileges(authorizationRef,
                                             (char *)pathToCommand,
                                             0,
                                             args,
                                             NULL);
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

-(Boolean)isAuthorized {
  if (authorizationRef == NULL) {
    return false;
  } else  {
    return true;
  }
}


@end
