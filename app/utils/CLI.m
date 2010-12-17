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

- (void)restart:(Application*)application {
  [self execute:[NSArray arrayWithObjects:@"restart", application.host, nil] elevated:NO];
}

// Inspired by: http://svn.kismac-ng.org/kmng/trunk/Subprojects/BIGeneric/BLAuthentication.m
- (id)execute:(NSArray *)arguments elevated:(BOOL)elevated {
  OSStatus error;
  char **argumentsAsCArray = NULL;
  unsigned int index;
  
  FILE *communicationPipe;
  NSMutableData *temp, *output;
  size_t bytesRead;
  NSString *data;
  
  if (elevated) {
    if ([self isAuthorized]) {
      if ([arguments count] > 0) {
        index = 0;
        argumentsAsCArray = malloc(sizeof(char*)*[arguments count]);
        while(index < [arguments count]) {
          argumentsAsCArray[index++] = (char*)[[arguments objectAtIndex:index] UTF8String];
        }
        argumentsAsCArray[index] = NULL;
      }
      error = AuthorizationExecuteWithPrivileges(authorizationRef, (char*)pathToCLI, 0, argumentsAsCArray, &communicationPipe);
      free(argumentsAsCArray);
      
      if (error == PPANE_SUCCESS)  {
        temp = [[NSMutableData dataWithLength:1024] autorelease];
        output = [[NSMutableData data] autorelease];
        while(bytesRead = fread([temp mutableBytes], 1024, 1, communicationPipe)) {
          [output appendData:temp];
        }
        data = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
        [data autorelease];
        
        NSLog(@"%d", communicationPipe);
        fclose(communicationPipe);
      } else {
        NSLog(@"AuthorizationExecuteWithPrivileges failed to execute the command (%d)", error);
        data = [[NSString alloc] initWithCString:"" encoding:NSUTF8StringEncoding];
      }
      
      return yaml_parse(data);
    } else {
      NSLog(@"Ignoring a privileged command becaus the pane isn't authorized");
      return NULL;
    }
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
  [ppane setStandardOutput:stdout];
  [ppane launch];
  [ppane waitUntilExit];
  
  if ([ppane terminationStatus] == PPANE_SUCCESS) {
    data = [[NSString alloc] initWithData:[[stdout fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    [data autorelease];
    return yaml_parse(data);
  } else {
    NSLog(@"NSTask failed to execute the command");
    return [[NSDictionary dictionary] autorelease];
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
