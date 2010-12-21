#import <Foundation/Foundation.h>

@interface Application : NSObject {
  NSString *host, *aliases, *path, *environment, *framework;
  BOOL dirty, valid;
}

@property (retain) NSString *host, *aliases, *path, *environment, *framework;
@property (assign, getter=isDirty) BOOL dirty;
@property (assign, getter=isValid) BOOL valid;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
