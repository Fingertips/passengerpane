#import <Foundation/Foundation.h>


@interface CLI : NSObject {
  AuthorizationRef authorizationRef;
  NSString *pathToCLI;
}

@property (retain) NSString *pathToCLI;

+ (id)sharedInstance;

- (NSArray *)listApplications;

- (Boolean)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments;

- (AuthorizationRef) authorizationRef;
- (void) setAuthorizationRef:(AuthorizationRef)ref;

- (void)deauthorize;
- (Boolean)isAuthorized;

@end
