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
- (void)restart;

- (id)execute:(NSArray *)arguments elevated:(BOOL)elevated;
- (id)execute:(NSArray *)arguments;

- (AuthorizationRef) authorizationRef;
- (void) setAuthorizationRef:(AuthorizationRef)ref;

- (void)deauthorize;
- (BOOL)isAuthorized;

@end
