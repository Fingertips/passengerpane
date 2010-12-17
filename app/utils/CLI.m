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
  
  NSLog(@"Retrieving a list of configured applications");
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
//  NSLog(@"Restarting application with hostname: %@", application.host);
//  [self execute:[NSArray arrayWithObjects:@"restart", application.host, nil] elevated:NO];
  
  [self execute:[NSArray arrayWithObjects:@"restart", nil] elevated:YES];
}

// Inspired by: http://svn.kismac-ng.org/kmng/trunk/Subprojects/BIGeneric/BLAuthentication.m
- (id)execute:(NSArray *)arguments elevated:(BOOL)elevated {
  OSStatus error;
  char **argumentsAsCArray = NULL;
  unsigned int index;
  
  FILE *communicationPipe;
  size_t bytesRead;
  NSMutableData *temp, *output;
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
      
      error = AuthorizationExecuteWithPrivileges(authorizationRef, [pathToCLI UTF8String], 0, argumentsAsCArray, &communicationPipe);
      free(argumentsAsCArray);
      
      if (error == PPANE_SUCCESS) {
        if (communicationPipe) {
//          output = [NSMutableData data];
//          temp = [NSMutableData dataWithLength:1024];
//          while(bytesRead = fread([temp mutableBytes], 1024, 1, communicationPipe)) {
//            NSLog(@"Read %d bytes", bytesRead);
//            [output appendData:[temp subdataWithRange:NSMakeRange(0, bytesRead)]];
//          }
//          fclose(communicationPipe);
        }
//        data = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
//        NSLog(@"%@", data);
        return NULL;
      } else {
        NSLog(@"AuthorizationExecuteWithPrivileges failed to execute the command (%d)", error);
        return NULL;
      }
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
