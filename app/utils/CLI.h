#import <Foundation/Foundation.h>


@interface CLI : NSObject {
  AuthorizationRef authorizationRef;
  NSString *pathToCLI;
}

@property (retain) NSString *pathToCLI;

+ (id)sharedInstance;

- (NSArray *)listApplications;

- (Boolean)execute:(NSArray *)arguments;
- (Boolean)execute:(NSArray *)arguments secure:(Boolean)secure;

- (Boolean)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments; // Remove

- (AuthorizationRef) authorizationRef;
- (void) setAuthorizationRef:(AuthorizationRef)ref;

- (void)deauthorize;
- (Boolean)isAuthorized;

@end
