
#import "SPAlertView.h"
#import "SPBorderedButton.h"

@interface SPAlertView()

@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) SPBorderedButton *dismissButton;

@end

@implementation SPAlertView

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
        
        // Add the button below message
        float buttonWidth = floatingViewWidth;
        float buttonHeight = 50;
        float buttonY = floatingViewHeight - buttonHeight;
        float buttonX = 0;
        
        UIColor *buttonBorderColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1];
        float buttonBorderWidth = 1;
        
        CGRect buttonFrame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
        SPBorderedButton *button = [SPBorderedButton buttonWithType:UIButtonTypeSystem];
        button.frame = buttonFrame;
        [button addBorderTopWithWidth:buttonBorderWidth andColor:buttonBorderColor];
        [button setTitle:@"Dismiss" forState:UIControlStateNormal];
        [button addTarget:self.delegate action:@selector(dismissButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _dismissButton = button;
        
        [floatingView addSubview:button];
    }
    return self;
}

- (void)setMessage:(NSString *)message {
    self.messageLabel.text = message;
}

- (NSString *)message {
    return self.messageLabel.text;
}

@end