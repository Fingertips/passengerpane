@interface PassengerLoader : NSObject
{}
@end
@implementation PassengerLoader
@end

static void __attribute__((constructor)) loadRubyPrefPane(void)
{
	RBBundleInit("PassengerPref.rb", [PassengerLoader class], nil);
}
