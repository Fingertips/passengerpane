#import <Foundation/Foundation.h>

enum {
  PPANE_SUCCESS = 0
};


@interface CLI : NSObject {
  AuthorizationRef authorizationRef;
  NSString *pathToCLI;
}

@property (retain) NSString *pathToCLI;

+ (id)sharedInstance;

- (NSArray *)listApplications;

- (NSDictionary *)execute:(NSArray *)arguments elevated:(BOOL)elevated;
- (NSDictionary *)execute:(NSArray *)arguments;

- (BOOL)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments; // Remove

- (AuthorizationRef) authorizationRef;
- (void) setAuthorizationRef:(AuthorizationRef)ref;

- (void)deauthorize;
- (BOOL)isAuthorized;

@end
