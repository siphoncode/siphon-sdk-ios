
#import "RNMixpanelManager.h"
#import "Mixpanel.h"

@interface RNMixpanelManager()

@property (nonatomic) Mixpanel *mixpanel;

@end

@implementation RNMixpanelManager

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(sharedInstanceWithToken:(NSString *)token) {
    self.mixpanel = [Mixpanel sharedInstanceWithToken:token];
}

RCT_EXPORT_METHOD(registerSuperProperties:(NSDictionary *)superProperties) {
    [self.mixpanel registerSuperProperties:superProperties];
}

RCT_EXPORT_METHOD(track:(NSString *)event) {
    [self.mixpanel track:event];
}

RCT_EXPORT_METHOD(identify:(NSString *)distinctID) {
    [self.mixpanel identify:distinctID];
}

RCT_EXPORT_METHOD(createAlias:(NSString *)alias forDistinctID:(NSString *)distinctID) {
    [self.mixpanel createAlias:alias forDistinctID:distinctID];
}

RCT_EXPORT_METHOD(trackWithProperties:(NSString *)event properties:(NSDictionary *)properties) {
    [self.mixpanel track:event properties:properties];
}

@end
