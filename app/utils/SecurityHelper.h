#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>

@interface SecurityHelper : NSObject
{
  AuthorizationRef authorizationRef;
}
+ sharedInstance;
- (BOOL)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments;
- (void)setAuthorizationRef:(AuthorizationRef)theAuthorizationRef;
- (AuthorizationRef)authorizationRef;
- (void)deauthorize;
- (BOOL)isAuthorized;
@end