#import "SPDevelopmentAppViewController.h"
#import "SPBundleManager.h"
#import "SPAppView.h"
#import "SPConstants.h"
#import "SPLoadingView.h"
#import "SPApiClient.h"
#import "SPNotificationStreamClient.h"
#import "SPLogStreamClient.h"
#import "RCTLog.h"

@interface SPDevelopmentAppViewController() <SPBundleManagerDelegate, SPLogStreamClientDelegate, SPNotificationStreamClientDelegate>

@property (nonatomic) NSString *appId;
@property (nonatomic) NSString *authToken;
@property (nonatomic) NSString *host;
@property (nonatomic) BOOL sandboxMode;
@property (nonatomic) BOOL devMode;
@property (weak, nonatomic) id<SPDevelopmentAppViewControllerDelegate>delegate;

@property (nonatomic) NSURL *bundlerURL;
@property (nonatomic) SPApiClient *apiClient;

@property (nonatomic) NSArray *progression;
@property (nonatomic) SPLoadingView *loadingView;
@property (nonatomic) SPAppView *appView;
@property (nonatomic) SPBundleManager *bundleManager;
@property (nonatomic) UIButton *exitButton;

@property (nonatomic) SPLogStreamClient *logStream;
@property (nonatomic) SPNotificationStreamClient *notificationStream;

// SPBundleManagerDelegate methods
- (void)bundleManagerInitialized:(SPBundleManager *)bundleManager;
- (void)fetchingAssets:(NSURLSessionDataTask *)fetchingAssetsDataTask;
- (void)fetchedAssets;

// SPLogStreamClientDelegate methods
- (void)logStreamError:(NSError *)error;

// SPNotificationStreamClientDelegate methods
- (void)notificationStreamError:(NSError *)error;
- (void)receivedNotification:(NSString *)notificationType;

- (void)bundleDidFinishLoading;
- (void)bundleFailedToLoad:(NSError *)error;
- (void)showLoadingView;
- (void)showAppView;
- (void)showErrorMessage:(NSError *)error;
- (void)broadcastLog:(NSString *)log;
- (void)reconnectToNotificationStream;
- (void)reconnectToLogStream;

@end

@implementation SPDevelopmentAppViewController

#define SANDBOX_SHOW_BACK_BUTTON { \
    if (self.sandboxMode) {\
        [self showExitButton];\
    }\
}

#define SANDBOX_HIDE_BACK_BUTTON { \
    if (self.sandboxMode) {\
        [self hideExitButton];\
    }\
}

- (instancetype)initWithAppId:(NSString *)appId andAuthToken:(NSString *)authToken andDelegate:(id)delegate andHost:(NSString *)host sandboxMode:(BOOL)sandboxMode devMode:(BOOL)devMode {
    if (self = [super init]) {
        _appId = appId;
        _authToken = authToken;
        _delegate = delegate;
        _sandboxMode = sandboxMode;
        _devMode = devMode;
        _host = host;
        _apiClient = [[SPApiClient alloc] initWithAppId:appId andAuthToken:authToken andHost:host];
    }
    return self;
}

- (instancetype)initWithAppId:(NSString *)appId andAuthToken:(NSString *)authToken andDelegate:(id)delegate sandboxMode:(BOOL)sandboxMode devMode:(BOOL)devMode {
    return [self initWithAppId:appId andAuthToken:authToken andDelegate:delegate andHost:SP_HOST sandboxMode:sandboxMode devMode:devMode];
}

- (instancetype)initWithAppId:(NSString *)appId andAuthToken:(NSString *)authToken {
    return [self initWithAppId:appId andAuthToken:authToken andDelegate:nil sandboxMode:NO devMode:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // The progression of events
    _progression = @[
                     @"bundleInitialized",
                     @"fetchingAssets",
                     @"fetchedAssets",
                     @"bundleLoaded"
                     ];
    
    void (^bundleManagerInitialized)(SPBundleManager *)= ^(SPBundleManager *bundleManager) {
        [self bundleManagerInitialized:bundleManager];
    };
    
    void (^bundleManagerInitializationFailed)(NSError *) = ^(NSError *error) {
        [self showErrorMessage:error];
    };
    
    [self showLoadingView];
    
    // Connect to our streams
    _logStream = [[SPLogStreamClient alloc] initWithAppId:self.appId andAuthToken:self.authToken andHost:self.host andDelegate:self];
    
    _notificationStream = [[SPNotificationStreamClient alloc] initWithAppId:self.appId andAuthToken:self.authToken andHost:self.host andDelegate:self];
    
    [SPBundleManager createBundleManagerWithAppId:self.appId andDelegate:self forSandbox:self.sandboxMode withDev:self.devMode success:bundleManagerInitialized error:bundleManagerInitializationFailed];
}

# pragma mark - Primary SPAppViewController methods

- (void)loadApp {
    void (^apiError)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showErrorMessage:error];
            SANDBOX_HIDE_BACK_BUTTON;
        });
    };
    
    // To be run when we have the bundler url
    void (^didRetrieveBundlerURL)(NSURL *) = ^(NSURL *bundlerURL) {
        // Cache the bundler URL
        self.bundlerURL = bundlerURL;
        [self.bundleManager loadBundleFromURL:bundlerURL withSuccess:^(NSURL *bundleURL) {
            [self bundleDidFinishLoading];
        } andError:^(NSError *error) {
            [self bundleFailedToLoad:error];
        }];
    };
    
    if (!self.bundlerURL) {
        [self.apiClient fetchBundlerURLWithSuccess:didRetrieveBundlerURL andError:apiError];
    } else {
        [self.bundleManager loadBundleFromURL:self.bundlerURL withSuccess:^(NSURL *bundleURL) {
            [self bundleDidFinishLoading];
        } andError:^(NSError *error) {
            [self bundleFailedToLoad:error];
        }];
    }
    
}

- (void)reloadApp {
    // Use after initialization has taken place
    SANDBOX_HIDE_BACK_BUTTON;
    [self.loadingView resetToProgress:@"bundleInitialized"];
    [self showLoadingView];
    [self.appView cleanUp];
    [self loadApp];
}

- (void)showAppView {
    if (self.appView) {
        [self.appView cleanUp];
    }
    SPAppView *appView = [[SPAppView alloc] initWithBundleURL:self.bundleManager.bundleURL redBox:self.devMode];
    self.appView = appView;
    [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.view addSubview:appView];
}

- (void)dismiss {
    UIView *snapshot = [self.view snapshotViewAfterScreenUpdates:YES];
    [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.view addSubview:snapshot];
    [self.logStream close];
    [self.notificationStream close];
    self.logStream = nil;
    self.notificationStream = nil;
    [self.appView cleanUp];
    [self dismissViewControllerAnimated:YES completion:^{}];
    if ([self.delegate respondsToSelector:@selector(appDismissed:)]) {
        [self.delegate appDismissed:self.appId];
    }
}

- (void)showErrorMessage:(NSError *)error {
    NSString *errMsg = [NSString stringWithFormat:@"%@ %@", error.localizedDescription, error.localizedRecoverySuggestion];
    [self.loadingView displayErrorMessage:errMsg
                             buttonTarget:self
                           buttonSelector:@selector(reloadApp)];
    SANDBOX_SHOW_BACK_BUTTON;
}

- (void)showLoadingView {
    if (!self.loadingView) {
        self.loadingView = [[SPLoadingView alloc] initWithFrame:[[UIScreen mainScreen] bounds]
                                                 andProgression:self.progression];
        self.loadingView.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
        [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    } else {
        [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    [self.view addSubview:self.loadingView];
}

- (void)showExitButton {
    if (!self.exitButton) {
        self.view.backgroundColor = [UIColor whiteColor];
        
        float width = 60;
        float height = 30;
        
        float marginRight = 20;
        float marginBottom = 20;
        
        float xCoordinate = CGRectGetMaxX(self.view.frame) - (width + marginRight);
        float yCoordinate = CGRectGetMaxY(self.view.frame) - (height + marginBottom);
        
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(dismiss) forControlEvents: UIControlEventTouchUpInside];
        
        [button setTitle:@"Exit" forState:UIControlStateNormal];
        button.frame = CGRectMake(xCoordinate, yCoordinate, width, height);
        button.backgroundColor = [UIColor colorWithRed:(107/255.0) green:(151/255.0) blue:(177/255.0) alpha:1];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 5;
        [self.view addSubview:button];
    }
    self.exitButton.hidden = NO;
}

- (void)hideExitButton {
    self.exitButton.hidden = YES;
}

- (void)broadcastLog:(NSString *)message {
    [self.logStream broadcastLog:message];
}

- (void)reconnectToNotificationStream {
    self.notificationStream = [[SPNotificationStreamClient alloc] initWithAppId:self.appId andAuthToken:self.authToken andHost:self.host andDelegate:self];
}

- (void)reconnectToLogStream {
    self.logStream = [[SPLogStreamClient alloc] initWithAppId:self.appId andAuthToken:self.authToken andHost:self.host andDelegate:self];
}

#pragma mark - SPBundleManagerDelegate methods

- (void)bundleManagerInitialized:(SPBundleManager *)bundleManager {
    self.loadingView.progress = @"bundleInitialized";
    self.bundleManager = bundleManager;
    [self loadApp];
}

- (void)fetchingAssets:(NSURLSessionDataTask *)fetchingAssetsDataTask {
    self.loadingView.progress = @"fetchingAssets";
}

- (void)fetchedAssets {
    self.loadingView.progress = @"fetchedAssets";
}

- (void)bundleDidFinishLoading {
    RCTSetLogThreshold(RCTLogLevelInfo);
    RCTSetLogFunction(^(RCTLogLevel level, RCTLogSource source, NSString *fileName,
                        NSNumber *lineNumber, NSString *message) {
        if (source == RCTLogSourceJavaScript) {
            NSString *msg = [NSString stringWithString:message];
            if ([msg rangeOfString:@"Unable to load source map"].location == NSNotFound) {
                [self broadcastLog:msg];
            }
        }
    });
    self.loadingView.progress = @"bundleLoaded";
    [self showAppView];
    SANDBOX_SHOW_BACK_BUTTON;
}

- (void)bundleFailedToLoad:(NSError *)error {
    [self showErrorMessage:error];
    SANDBOX_HIDE_BACK_BUTTON;
    
}

#pragma mark - SPLogStreamClientDelegate methods

- (void)logStreamError:(NSError *)error {
    [self performSelector:@selector(reconnectToLogStream) withObject:self afterDelay:5];
}

#pragma mark - SPNotificationStreamClientDelegate methods

- (void)receivedNotification:(NSString *)notificationType {
    if ([notificationType isEqualToString:@"app_updated"]) {
        [self reloadApp];
    }
    return;
}

- (void)notificationStreamError:(NSError *)error {
    [self performSelector:@selector(reconnectToNotificationStream) withObject:self afterDelay:5];
}

@end