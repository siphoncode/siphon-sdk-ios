
#import "SPLoadingView.h"

@interface SPLoadingView()

@property (nonatomic) UILabel *errorMessageLabel;
@property (nonatomic) UIButton *button;
@property (nonatomic) UIProgressView *progressView;

@end

@implementation SPLoadingView

- (instancetype)initWithFrame:(CGRect)frame
               andProgression:(NSArray *)progression {
    if (self = [super initWithFrame:frame]) {
        _progression = progression;
        self.backgroundColor = [UIColor whiteColor];
        CGRect messageFrame = CGRectZero;
        messageFrame.size.width =  self.frame.size.width * 0.75;
        messageFrame.size.height = 100;
        messageFrame.origin.x = self.frame.size.width / 2 - messageFrame.size.width / 2;
        messageFrame.origin.y = self.frame.size.height / 2 - messageFrame.size.height - 20;
        _errorMessageLabel = [[UILabel alloc] initWithFrame:messageFrame];
        
        self.errorMessageLabel.textAlignment = NSTextAlignmentCenter;
        self.errorMessageLabel.textColor = [UIColor darkGrayColor];
        self.errorMessageLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:14];
        self.errorMessageLabel.backgroundColor = [UIColor clearColor];
        self.errorMessageLabel.hidden = YES;
        self.errorMessageLabel.numberOfLines = 5;
        [self addSubview:self.errorMessageLabel];
        
        // Add a button
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.button = button;
        CGRect buttonFrame = CGRectZero;
        buttonFrame.size.width = 0.4 * self.frame.size.width;
        buttonFrame.size.height = 30;
        buttonFrame.origin.x = self.frame.size.width / 2 - buttonFrame.size.width / 2;
        buttonFrame.origin.y = self.frame.size.height / 2 + buttonFrame.size.height + 20;
        button.frame = buttonFrame;
        [self.button setTitle:@"Reload" forState:UIControlStateNormal];
        self.button.hidden = YES;
        [self addSubview:button];
        
        // Add a progress view as the subview & center it
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        CGRect frame = progressView.frame;
        frame.origin.x = self.frame.size.width / 2 - frame.size.width / 2;
        frame.origin.y = self.frame.size.height / 2;
        progressView.frame = frame;
        progressView.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
        _progressView = progressView;
        [self addSubview:self.progressView];
    }
    return self;
}

- (void)reset {
    self.progressView.progress = 0;
    self.errorMessageLabel.text = @"";
    self.button.hidden = YES;
}

- (void)resetToProgress:(NSString *)progress {
    // Like setProgress but not animated
    self.errorMessageLabel.hidden = YES;
    NSUInteger progressionLength = self.progression.count;
    int i;
    BOOL found = NO;
    for (i = 0; i < progressionLength; i++) {
        if (self.progression[i] == progress) {
            found = YES;
            break;
        }
    }
    if (!found) {
        // Item not in the progression
        return;
    } else {
        float numericalProgress = ((float)i + 1.0)/ (float)progressionLength;
        [self.progressView setProgress:numericalProgress animated:NO];
    }
}

- (void)displayErrorMessage:(NSString *)message buttonTarget:(id)target
             buttonSelector:(SEL)buttonPressed {
    [self.button addTarget:target action:buttonPressed forControlEvents:UIControlEventTouchUpInside];
    self.errorMessageLabel.text = message;
    self.errorMessageLabel.hidden = NO;
    self.button.hidden = NO;
}

- (void)setProgress:(NSString *)progress {
    NSUInteger progressionLength = self.progression.count;
    int i;
    BOOL found = NO;
    for (i = 0; i < progressionLength; i++) {
        if (self.progression[i] == progress) {
            found = YES;
            break;
        }
    }
    if (!found) {
        // Item not in the progression
        return;
    } else {
        float numericalProgress = ((float)i + 1.0)/ (float)progressionLength;
        [self.progressView setProgress:numericalProgress animated:YES];
        _progress = progress;
    }
}

@end