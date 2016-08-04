#import "SPUpdatingView.h"
# import "SPBorderedButton.h"

@interface SPUpdatingView()

@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic) SPBorderedButton *retryButton;
@property (nonatomic) SPBorderedButton *cancelButton;

@end

@implementation SPUpdatingView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Add a vibrant blur view
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:blur];
        
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        UIVisualEffectView *vibrantView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        
        blurView.frame = frame;
        vibrantView.frame = frame;
        
        [self addSubview:blurView];
        [self addSubview:vibrantView];
        
        // Make the floating view that shows the progress bar and any buttons
        float floatingViewWidth = frame.size.width * 0.65;
        float floatingViewHeight = frame.size.height * 0.25;
        float floatingViewX = (frame.size.width / 2) - (floatingViewWidth / 2);
        float floatingViewY = (frame.size.height / 2) - (floatingViewHeight / 2);
        CGRect floatingViewFrame = CGRectMake(floatingViewX, floatingViewY, floatingViewWidth, floatingViewHeight);
        UIView *floatingView = [[UIView alloc] initWithFrame:floatingViewFrame];
        floatingView.backgroundColor = [UIColor whiteColor];
        floatingView.layer.cornerRadius = 12;
        [self addSubview:floatingView];
        
        // Add the main label (relative to the floating view)
        float messageLabelWidth = floatingViewWidth * 0.7;
        float margin = (floatingViewWidth - messageLabelWidth) / 2;
        float messageLabelX = margin;
        float messageLabelY = margin;
        float messageLabelHeight = (floatingViewHeight - margin) * 0.45;
        CGRect messageLabelFrame = CGRectMake(messageLabelX, messageLabelY, messageLabelWidth, messageLabelHeight);
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:messageLabelFrame];
        messageLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        messageLabel.textColor = [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1];
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.adjustsFontSizeToFitWidth = YES;
        messageLabel.numberOfLines = 3;
        _messageLabel = messageLabel;
        [floatingView addSubview:messageLabel];
        
        // Add the progress view (relative to the floating view)
        float progressViewWidth = floatingViewWidth * 0.7;
        float progressViewX = (floatingViewWidth - progressViewWidth) / 2;
        float progressViewY = messageLabelY + messageLabelHeight;
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        CGRect progressViewFrame = CGRectMake(progressViewX, progressViewY, progressViewWidth, progressView.frame.size.height);
        progressView.frame = progressViewFrame;
        _progressView = progressView;
        [floatingView addSubview:progressView];
        
        // Add the buttons below the progress view
        float buttonWidth = floatingViewWidth / 2;
        float buttonY = progressViewY + progressView.frame.size.height + 20;
        float buttonHeight = floatingViewHeight - buttonY;
        float retryButtonX = 0;
        float cancelButtonX = buttonWidth;
        
        UIColor *buttonBorderColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1];
        float buttonBorderWidth = 1;
        
        CGRect retryButtonFrame = CGRectMake(retryButtonX, buttonY, buttonWidth, buttonHeight);
        SPBorderedButton *retryButton = [SPBorderedButton buttonWithType:UIButtonTypeSystem];
        retryButton.frame = retryButtonFrame;
        [retryButton addBorderTopWithWidth:buttonBorderWidth andColor:buttonBorderColor];
        [retryButton setTitle:@"Retry" forState:UIControlStateNormal];
        [retryButton addTarget:self.delegate action:@selector(retryButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _retryButton = retryButton;
        
        CGRect cancelButtonFrame = CGRectMake(cancelButtonX, buttonY, buttonWidth, buttonHeight);
        SPBorderedButton *cancelButton = [SPBorderedButton buttonWithType:UIButtonTypeSystem];
        cancelButton.frame = cancelButtonFrame;
        [cancelButton addBorderTopWithWidth:buttonBorderWidth andColor:buttonBorderColor];
        [cancelButton addBorderLeftWithWidth:buttonBorderWidth andColor:buttonBorderColor];
        [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [cancelButton addTarget:self.delegate action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton = cancelButton;
        
        [floatingView addSubview:retryButton];
        [floatingView addSubview:cancelButton];
    }
    return self;
}

- (void)setMessage:(NSString *)message {
    self.messageLabel.text = message;
}

- (NSString *)message {
    return self.messageLabel.text;
}

- (void)setProgressAnimated:(float)progress {
    [self.progressView setProgress:progress animated:YES];
}

- (void)setProgress:(float)progress {
    [self.progressView setProgress:progress animated:NO];
}

- (float)progress {
    return self.progressView.progress;
}

- (void)setProgressVisible:(BOOL)progressVisible {
    self.progressView.hidden = !progressVisible;
}

- (BOOL)progressVisible {
    return !self.progressView.hidden;
}

- (void)setRetryButtonActive:(BOOL)retryButtonActive {
    self.retryButton.active = retryButtonActive;
}

- (BOOL)retryButtonActive {
    return self.retryButton.active;
}

- (void)setCancelButtonActive:(BOOL)cancelButtonActive {
    self.cancelButton.active = cancelButtonActive;
}

- (BOOL)cancelButtonActive {
    return self.cancelButton.active;
}

@end