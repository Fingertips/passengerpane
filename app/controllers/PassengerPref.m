@interface PassengerLoader : NSObject
{}
@end
@implementation PassengerLoader
@end

static void __attribute__((constructor)) loadRubyPrefPane(void)
{
	RBBundleInit("passenger_pref.rb", [PassengerLoader class], nil);
}
