#import <Foundation/Foundation.h>
#import "Common.h"

enum {
  PPANE_DEVELOPMENT = 0,
  PPANE_PRODUCTION  = 1
};

@interface Application : NSObject {
  id delegate;
  
  NSString *host, *aliases, *path, *configFilename;
  NSUInteger environment;
  BOOL dirty, valid, fresh;
  
  NSDictionary *beforeChanges;
}

@property (assign) id delegate;
@property (assign) NSString *host, *aliases, *path, *configFilename;
@property (assign) NSUInteger environment;
@property (assign, getter=isDirty) BOOL dirty;
@property (assign, getter=isValid) BOOL valid;
@property (assign, getter=isFresh) BOOL fresh;
@property (readonly) NSDictionary *beforeChanges;

- (id) initWithAttributes:(NSDictionary *)attributes;
- (id) initWithDirectory:(NSString *)aPath;
- (void) updateAttributes:(NSDictionary *)attributes;
- (NSMutableDictionary*) toDictionary;
- (NSArray*) toArgumentArray;
- (void) validate;
- (void) checkChanges;
- (void) didApplyChanges;
- (void) revert;

@end
