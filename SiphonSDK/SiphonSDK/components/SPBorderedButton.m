
#import "SPBorderedButton.h"

@implementation SPBorderedButton

- (void)addBorderLeftWithWidth:(float)width andColor:(UIColor *)color {
    UIView *borderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, self.frame.size.height)];
    borderView.backgroundColor = color;
    [self addSubview:borderView];
}

- (void)addBorderRightWithWidth:(float)width andColor:(UIColor *)color {
    UIView *borderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.width, width, self.frame.size.height)];
    borderView.backgroundColor = color;
    [self addSubview:borderView];
}

- (void)addBorderTopWithWidth:(float)width andColor:(UIColor *)color {
    UIView *borderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, width)];
    borderView.backgroundColor = color;
    [self addSubview:borderView];
}

- (void)addBorderBottomWithWidth:(float)width andColor:(UIColor *)color {
    UIView *borderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, width)];
    borderView.backgroundColor = color;
    [self addSubview:borderView];
}

- (void)setActive:(BOOL)active {
    if (active) {
        self.userInteractionEnabled = YES;
        self.alpha = 1;
    } else {
        self.userInteractionEnabled = NO;
        self.alpha = 0.3;
    }
}

- (BOOL)active {
    return self.userInteractionEnabled;
}

@end