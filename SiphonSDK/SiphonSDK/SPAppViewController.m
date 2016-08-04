#import "SPAlertView.h"
#import "SPApiClient.h"
#import "SPAppViewController.h"
#import "SPAppView.h"
#import "SPBundleManager.h"
#import "SPConstants.h"
#import "SPUpdatingView.h"

@interface SPAppViewController() <SPAlertViewDelegate, SPBundleManagerDelegate, SPUpdatingViewDelegate>

@property (nonatomic) NSString *appId;
@property (nonatomic) NSString *host;
@property (nonatomic) NSString *submissionId;
@property (nonatomic) SPAlertView *alertView;
@property (nonatomic) SPAppView *appView;
@property (nonatomic) SPBundleManager *bundleManager;
@property (nonatomic) SPUpdatingView *updatingView;
@property (nonatomic) BOOL shouldLoadLocal;
@property (nonatomic) NSTimer *fetchingAssetsTimer;
@property (nonatomic) NSURLSessionDataTask *fetchingAssetsTask;

- (void)update;
- (void)showAppView;
- (void)refreshAppView;
- (void)presentUpdatingView;
- (void)dismissUpdatingView;
- (void)resetUpdatingView;
- (void)updateInteractionEnabled:(BOOL)enabled withMessage:(NSString *)message;
- (void)presentAlertView:(NSString *)message;
- (void)dismissButtonPressed;
- (void)updateIsSlow;

- (void)fetchingAssets:(NSURLSessionDataTask *)fetchingAssetsDataTask;
- (void)fetchedAssets;

- (void)retryButtonPressed;
- (void)cancelButtonPressed;

@end

@implementation SPAppViewController

- (instancetype)initWithAppId:(NSString *)appId andSubmissionId:(NSString *)submissionId andHost:(NSString *)host {
    if (self = [super init]) {
        _appId = appId;
        _host = host;
        // Base version book keeping
        NSString *lastStoredBaseVersion = [[NSUserDefaults standardUserDefaults] valueForKey:[NSString stringWithFormat:@"%@.baseVersion", SP_STORAGE_PREFIX]];
        
        if (!lastStoredBaseVersion) {
            lastStoredBaseVersion = @"";
        }
        
        if (![lastStoredBaseVersion isEqualToString:SP_BASE_VERSION]) {
            // The binary has been updated or just installed, so we update the current base version and submission id
            // in NSUserDefaults (the submission id should reflect the one supplied to the init method)
            [SPBundleManager cleanAppDirectory:appId];
            [[NSUserDefaults standardUserDefaults] setValue:SP_BASE_VERSION forKey:[NSString stringWithFormat:@"%@.baseVersion", SP_STORAGE_PREFIX]];
            [[NSUserDefaults standardUserDefaults] setValue:submissionId forKey:[NSString stringWithFormat:@"%@.submissionId", SP_STORAGE_PREFIX]];
            _submissionId = submissionId;
            _shouldLoadLocal = YES;
        } else {
            // The submission id should be set to the last one stored
            _submissionId = [[NSUserDefaults standardUserDefaults] valueForKey:[NSString stringWithFormat:@"%@.submissionId", SP_STORAGE_PREFIX]];
            _shouldLoadLocal = NO;
        }
        _alertView = [[SPAlertView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        _updatingView = [[SPUpdatingView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    
    return self;
}

- (instancetype)initWithAppId:(NSString *)appId andSubmissionId:(NSString *)submissionId {
    return [[SPAppViewController alloc] initWithAppId:appId andSubmissionId:submissionId andHost:SP_HOST];
}

- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor whiteColor];
    
    void (^bundleManagerInitialized)(SPBundleManager *)= ^(SPBundleManager *bundleManager) {
        self.bundleManager = bundleManager;
        
        // Note that shouldLoadLocal refers to loading the app from the bundled assets.zip archive. This is set in the init method.
        // This occurs on a fresh install or hard update. When loading locally, the archive is decompressed
        // and the contents are placed in the app directory, where they are access by the app view.
        // If we have not had a fresh install or hard update, then we should always load from here as it
        // will contain the latest version of the app, which may have recevied soft updates.
        if (self.shouldLoadLocal) {
            [self.bundleManager loadLocalBundleWithSuccess:^(NSURL *bundleURL) {
                self.shouldLoadLocal = NO;
                [self showAppView];
                [self updateIfTimeOK];
            } andError:^(NSError *error) {}];
        } else {
            [self showAppView];
            [self updateIfTimeOK];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateIfTimeOK) name:UIApplicationDidBecomeActiveNotification object:nil];
    };
    void (^bundleManagerInitializationFailed)(NSError *) = ^(NSError *error) {};
    
    [SPBundleManager createBundleManagerWithAppId:self.appId andDelegate:self forSandbox:NO withDev:NO success:bundleManagerInitialized error:bundleManagerInitializationFailed];
}

# pragma mark - Primary Methods

- (void)updateIfTimeOK {
    // Update if 4 hours has passed since the last update was run
    NSDate *lastChecked = [[NSUserDefaults standardUserDefaults] valueForKey:[NSString stringWithFormat:@"%@.checkedForUpdate", SP_STORAGE_PREFIX]];
    if ([lastChecked isKindOfClass:[NSDate class]]) {
        if (-[lastChecked timeIntervalSinceNow] < (4*60*60)) {
            return;
        }
    }
    [self update];
}

- (void)update {
    // Check that a suitable amount of time has passed since we last checked for an update
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:[NSString stringWithFormat:@"%@.checkedForUpdate", SP_STORAGE_PREFIX]];
    // Get the submission_id and, if an update is required, the bundler url from which it can be downloaded from
    void (^submissionInfoReceived)(NSDictionary *) = ^(NSDictionary *submissionInfo) {
        NSString *latestSubmissionId = submissionInfo[@"submission_id"];
        NSString *updateURLString = submissionInfo[@"bundler_url"];
        if ([updateURLString length] > 0 && [latestSubmissionId length] > 0) {
            // An update is available for this app running on this base version; retrieve it
            if ([self.updatingView isDescendantOfView:self.view]) {
                [self resetUpdatingView];
            } else {
                [self presentUpdatingView];
            }
            
            [self.bundleManager loadBundleFromURL:[NSURL URLWithString:updateURLString] withSuccess:^(NSURL *bundleURL) {
                [[NSUserDefaults standardUserDefaults] setValue:latestSubmissionId forKey:[NSString stringWithFormat:@"%@.submissionId", SP_STORAGE_PREFIX]];
                [self refreshAppView];
                [self dismissUpdatingView];
            } andError:^(NSError *error) {
                if (self.fetchingAssetsTimer) {
                    [self.fetchingAssetsTimer invalidate];
                }
                [self updateInteractionEnabled:YES withMessage:@"A problem occurred while updating your app."];
            }];
        }
    };
    
    void (^errorRetrievingSubmissionInfo)(NSError *) = ^(NSError *error) {
        if (error.code == SPApiClientUserError)  {
            NSString *message = error.localizedDescription;
            if ([self.updatingView isDescendantOfView:self.view]) {
                [self updateInteractionEnabled:YES withMessage:message];
            } else {
                [self presentAlertView:message];
            }
        } else if ([self.updatingView isDescendantOfView:self.view]) {
            [self updateInteractionEnabled:YES withMessage:@"A problem occurred while updating your app."];
        }
    };
    
    NSString *submissionId = [[NSUserDefaults standardUserDefaults] valueForKey:[NSString stringWithFormat:@"%@.submissionId", SP_STORAGE_PREFIX]];
    [SPApiClient fetchDataForSubmission:submissionId atHost:self.host withSuccess:submissionInfoReceived andError:errorRetrievingSubmissionInfo];
}

- (void)showAppView {
    if (self.appView) {
        [self.appView cleanUp];
    }
    SPAppView *appView = [[SPAppView alloc] initWithBundleURL:self.bundleManager.bundleURL andErrorMessage:@"There was a problem rendering the app." redBox:NO];
    self.appView = appView;
    [self.view addSubview:appView];
}

- (void)refreshAppView {
    if ([self.appView isDescendantOfView:self.view]) {
        SPAppView *appView = [[SPAppView alloc] initWithBundleURL:self.bundleManager.bundleURL andErrorMessage:@"There was a problem rendering the app." redBox:NO];
        [self.view insertSubview:appView aboveSubview:self.appView];
        [self.appView removeFromSuperview];
        [self.appView cleanUp];
        self.appView = appView;
    }
}

- (void)presentUpdatingView {
    [self resetUpdatingView];
    // Fade in
    self.updatingView.alpha = 0;
    [self.view addSubview:self.updatingView];
    [UIView beginAnimations:@"FadeIn" context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.updatingView.alpha = 1;
    [UIView commitAnimations];
}

- (void)presentAlertView:(NSString *)message {
    self.alertView.message = message;
    // Fade in
    self.alertView.alpha = 0;
    [self.view addSubview:self.alertView];
    [UIView beginAnimations:@"FadeIn" context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.alertView.alpha = 1;
    [UIView commitAnimations];
}

- (void)dismissButtonPressed {
    if ([self.alertView isDescendantOfView:self.view]) {
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.alertView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.alertView removeFromSuperview];
        }];
    }
}

- (void)dismissUpdatingView {
    if ([self.updatingView isDescendantOfView:self.view]) {
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.updatingView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.updatingView removeFromSuperview];
        }];
    }
}

- (void)resetUpdatingView {
    self.updatingView.message = @"One moment, we're updating the app...";
    self.updatingView.progressVisible = YES;
    self.updatingView.retryButtonActive = NO;
    self.updatingView.cancelButtonActive = NO;
    self.updatingView.progress = 0;
}

- (void)updateInteractionEnabled:(BOOL)enabled withMessage:(NSString *)message {
    self.updatingView.retryButtonActive = enabled;
    self.updatingView.cancelButtonActive = enabled;
    self.updatingView.message = message;
}

- (void)updateIsSlow {
    [self updateInteractionEnabled:YES withMessage:@"Sorry, it's taking a while..."];
}

- (void)cancelDownload {
    if (self.fetchingAssetsTask && (self.fetchingAssetsTask.state == NSURLSessionTaskStateRunning)) {
        [self.fetchingAssetsTask cancel];
        self.fetchingAssetsTask = nil;
    }
}

# pragma mark - SPUpdatingViewDelegate Methods
- (void)retryButtonPressed {
    [self cancelDownload];
    [self resetUpdatingView];
    [self update];
}

- (void)cancelButtonPressed {
    [self cancelDownload];
    [self dismissUpdatingView];
}
# pragma mark - SPBundleManagerDelegate Methods

- (void)fetchingAssets:(NSURLSessionDataTask *)fetchingAssetsDataTask {
    // This part of the update process is cancellable.
    self.fetchingAssetsTask = fetchingAssetsDataTask;
    self.fetchingAssetsTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(updateIsSlow) userInfo:nil repeats:NO];
    [self.updatingView setProgressAnimated:0.3];
}

- (void)fetchedAssets {
    [self.fetchingAssetsTimer invalidate];
    [self updateInteractionEnabled:NO withMessage:@"Installing..."];
    [self.updatingView setProgressAnimated:0.6];
}

@end

