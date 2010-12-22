#import <Foundation/Foundation.h>
#import "Common.h"

@interface Application : NSObject {
  NSString *host, *aliases, *path, *framework, *environment, *vhostAddress, *userDefinedData;
  BOOL dirty, valid;
}

@property (retain) NSString *host, *aliases, *path, *framework, *environment, *vhostAddress, *userDefinedData;
@property (assign, getter=isDirty) BOOL dirty;
@property (assign, getter=isValid) BOOL valid;

- (id) initWithDictionary:(NSDictionary*)dictionary;
- (void) validate;

@end
