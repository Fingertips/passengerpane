#import <Foundation/Foundation.h>


@interface CLI : NSObject {
  AuthorizationRef authorizationRef;
}

@property (retain) authorizationRef;

+ (id)sharedInstance;

@end
