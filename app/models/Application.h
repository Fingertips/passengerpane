#import <Foundation/Foundation.h>

@interface Application : NSObject {
  NSString *host, *aliases, *path, *environment, *framework;
  
  BOOL dirty, valid;
}

@property (retain) NSString *host, *aliases, *path, *environment, *framework;
@property BOOL dirty, valid;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
