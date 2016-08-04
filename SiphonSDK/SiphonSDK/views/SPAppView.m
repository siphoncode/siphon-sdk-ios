
#import "SPAppView.h"
#import "RCTRootView.h"
#import "RCTExceptionsManager.h"
#import "RCTLog.h"
#import "RCTRedBox.h"
#import "RCTBridge+Private.h"
#import "RCTJSCExecutor.h"

@interface SPAppView() <RCTExceptionsManagerDelegate>

@property (nonatomic) RCTRootView *rootView;
@property (nonatomic, weak) NSURL *bundleURL;
@property (nonatomic) UILabel *errorMessageLabel;
@property (nonatomic) NSString *errorMessage;
@property (nonatomic) NSMutableArray *errorMessages;
@property (nonatomic) BOOL redBox;

// RCTExceptionsManagerDelegate methods
- (void)handleSoftJSExceptionWithMessage:(NSString *)message stack:(NSArray *)stack exceptionId:(NSNumber *)exceptionId;
- (void)handleFatalJSExceptionWithMessage:(NSString *)message stack:(NSArray *)stack exceptionId:(NSNumber *)exceptionId;

- (void)presentFatalError;

@end

@implementation SPAppView

- (id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        
        RCTSetFatalHandler(^(NSError *error) {});
        __weak typeof(self) weakSelf = self;
        RCTBridge *bridge = [[RCTBridge alloc] initWithBundleURL:self.bundleURL moduleProvider:^{
            return @[[[RCTExceptionsManager alloc] initWithDelegate:weakSelf]];
        } launchOptions:nil];
        
        RCTRootView *rv = [[RCTRootView alloc] initWithBridge:bridge moduleName:@"App" initialProperties:nil];
        _rootView = rv;
        _errorMessages = [[NSMutableArray alloc] init];
        [self addSubview:rv];
        rv.frame = self.bounds;
    }
    
    return self;
}

- (instancetype)initWithBundleURL:(NSURL *)url andErrorMessage:(NSString *)errorMessage redBox:(BOOL)redBox {
    _bundleURL = url;
    _errorMessage = errorMessage;
    _redBox = redBox;
    return [self initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
}

- (instancetype)initWithBundleURL:(NSURL *)url redBox:(BOOL)redBox {
    NSString *errorMessage;
    if (redBox) {
        // Default red box message
        errorMessage = @"An error occurred while rendering your app:";
    } else {
        errorMessage = @"There was a problem rendering your app. You can view the logs in the terminal.";
    }
    return [[SPAppView alloc] initWithBundleURL:url andErrorMessage:errorMessage redBox:redBox];
}

- (void)cleanUp {
    [self.rootView.bridge invalidate];
}

- (void)handleSoftJSExceptionWithMessage:(NSString *)message stack:(NSArray *)stack exceptionId:(NSNumber *)exceptionId {}

- (void)handleFatalJSExceptionWithMessage:(NSString *)message stack:(NSArray *)stack exceptionId:(NSNumber *)exceptionId {
    [self.errorMessages addObject:message];
    // Add error screen
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentFatalError];
    });
}

- (void)presentFatalError {
    // The app was unable to render due to a JS error
    if (!self.redBox) {
        CGRect messageFrame = CGRectZero;
        messageFrame.size.width =  self.frame.size.width;
        messageFrame.size.height = self.frame.size.height;
        messageFrame.origin.x = self.frame.size.width / 2 - messageFrame.size.width / 2;
        messageFrame.origin.y = self.frame.size.height / 2 - messageFrame.size.height / 2;
        UILabel *errorMessageLabel = [[UILabel alloc] initWithFrame:messageFrame];
        
        errorMessageLabel.textAlignment = NSTextAlignmentCenter;
        errorMessageLabel.textColor = [UIColor darkGrayColor];
        errorMessageLabel.backgroundColor = [UIColor clearColor];
        errorMessageLabel.numberOfLines = 3;
        
        errorMessageLabel.text = _errorMessage;
        
        // Remove any current subview we have and insert the loading view
        [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self addSubview:errorMessageLabel];
    } else {
        self.backgroundColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
        CGRect errorTitleFrame = CGRectMake(10, 20, self.rootView.frame.size.width - 10, 50);
        UILabel *errorTitle = [[UILabel alloc] initWithFrame:errorTitleFrame];
        errorTitle.text = self.errorMessage;
        errorTitle.lineBreakMode = NSLineBreakByWordWrapping;
        errorTitle.numberOfLines = 0;
        errorTitle.font = [UIFont boldSystemFontOfSize:19];
        errorTitle.textColor = [UIColor whiteColor];
        
        float errorMessageY = errorTitleFrame.size.height + errorTitleFrame.origin.y + 15;
        float errorMessageHeight = self.rootView.frame.size.height - errorMessageY;
        CGRect errorMessageFrame = CGRectMake(self.rootView.frame.origin.x, errorMessageY, self.rootView.frame.size.width, errorMessageHeight);
        UITextView *errorMessageView = [[UITextView alloc] initWithFrame:errorMessageFrame];
        errorMessageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        errorMessageView.textContainerInset = UIEdgeInsetsMake(0, 6, 0, 6);
        [errorMessageView setEditable:NO];
        
        NSString *errorMessage = [self.errorMessages objectAtIndex:0];
        errorMessageView.text = errorMessage;
        errorMessageView.font = [UIFont boldSystemFontOfSize:15];
        errorMessageView.textColor = [UIColor whiteColor];
        errorMessageView.backgroundColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
        [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self addSubview:errorMessageView];
        [self addSubview:errorTitle];
    }
}

@end