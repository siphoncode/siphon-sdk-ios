
#import "SPAppManager.h"
#import "SPAppView.h"
#import "SPBundleManager.h"
#import "SPLoadingView.h"
#import "UIView+React.h"
#import "SPLogStreamClient.h"

#import "SPDevelopmentAppViewController.h"
#import "RCTUtils.h"

@interface SPAppManager() <SPDevelopmentAppViewControllerDelegate>

@property (nonatomic) UIView *view;
@property (nonatomic) UIViewController *viewController;

@property (nonatomic) NSString *appId;
@property (nonatomic) NSString *authToken;
@property (nonatomic) NSArray *progression;
@property (nonatomic) SPLoadingView *loadingView;
@property (nonatomic) SPBundleManager *bundleManager;

@property (nonatomic) SPLogStreamClient *logStream;

- (void)appDismissed:(NSString *)appId;

@end

@implementation SPAppManager

RCT_EXPORT_MODULE() // resolves to SPApp

RCT_EXPORT_METHOD(presentApp:(NSString *)appId authToken:(NSString *)authToken devMode:(BOOL)devMode) {
    UIViewController *presentingController = RCTKeyWindow().rootViewController;
    
    while (presentingController.presentedViewController) {
        presentingController = presentingController.presentedViewController;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        SPDevelopmentAppViewController *appViewController = [[SPDevelopmentAppViewController alloc] initWithAppId:appId andAuthToken:authToken andDelegate:self sandboxMode:TRUE devMode:devMode];
        [appViewController.view setFrame:CGRectMake(0,0, presentingController.view.frame.size.width, presentingController.view.frame.size.height)];
        [presentingController presentViewController:appViewController animated:YES completion:nil];
    });
}

- (void)appDismissed:(NSString *)appId {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *event = @{@"name": @"appDismissed", @"appId": appId};
        [self.bridge.eventDispatcher sendDeviceEventWithName:@"appDismissed" body:event];
    });
}

@end