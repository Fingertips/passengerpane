#import <Foundation/Foundation.h>
#import <YAML/YAML.h>
#import "Application.h"

enum {
  PPANE_SUCCESS = 0
};


@interface CLI : NSObject {
  AuthorizationRef authorizationRef;
  NSString *pathToCLI;
}

@property (retain) NSString *pathToCLI;

+ (id)sharedInstance;

- (NSMutableArray *)listApplications;

- (id)execute:(NSArray *)arguments elevated:(BOOL)elevated;
- (id)execute:(NSArray *)arguments;

- (BOOL)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments; // Remove

- (AuthorizationRef) authorizationRef;
- (void) setAuthorizationRef:(AuthorizationRef)ref;

- (void)deauthorize;
- (BOOL)isAuthorized;

@end
