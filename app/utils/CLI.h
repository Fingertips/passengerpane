#import <Foundation/Foundation.h>


@interface CLI : NSObject {
  AuthorizationRef authorizationRef;
  NSString *pathToCLI;
}

@property (retain) NSString *pathToCLI;

+ (id)sharedInstance;

- (NSArray *)listApplications;

- (BOOL)execute:(NSArray *)arguments;
- (BOOL)execute:(NSArray *)arguments secure:(BOOL)secure;

- (BOOL)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments; // Remove

- (AuthorizationRef) authorizationRef;
- (void) setAuthorizationRef:(AuthorizationRef)ref;

- (void)deauthorize;
- (BOOL)isAuthorized;

@end
