#import <Foundation/Foundation.h>
#import <YAML/YAML.h>
#import "Application.h"

enum {
  PPANE_SUCCESS = 0
};


@interface CLI : NSObject {
  id appDelegate;
  AuthorizationRef authorizationRef;
  NSString *pathToCLI;
}

@property (assign) id appDelegate;
@property (assign) NSString *pathToCLI;

+ (id) sharedInstance;

- (NSMutableArray *) listApplications;
- (void) add:(Application *)application;
- (void) update:(Application *)application;
- (void) restart:(Application *)application;
- (void) restart;

- (id) execute:(NSArray *)arguments elevated:(BOOL)elevated;
- (id) execute:(NSArray *)arguments;

- (AuthorizationRef) authorizationRef;
- (void) setAuthorizationRef:(AuthorizationRef)ref;

- (void) deauthorize;
- (BOOL) isAuthorized;

// For testing purposed only
- (void) fakeAuthorize;

@end
