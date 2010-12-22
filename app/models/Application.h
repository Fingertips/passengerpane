#import <Foundation/Foundation.h>
#import "Common.h"

enum {
  PPANE_DEVELOPMENT = 0,
  PPANE_PRODUCTION  = 1
};

@interface Application : NSObject {
  NSArray *environments;
  
  NSString *host, *aliases, *path;
  NSUInteger environment;
  BOOL dirty, valid;
  
  NSDictionary *beforeChanges;
}

@property (retain) NSString *host, *aliases, *path;
@property (assign) NSUInteger environment;
@property (assign, getter=isDirty) BOOL dirty;
@property (assign, getter=isValid) BOOL valid;

- (id) initWithDictionary:(NSDictionary*)dictionary;
- (NSMutableDictionary*) toDictionary;
- (void) validate;

@end
