
@protocol SPAlertViewDelegate <NSObject>

- (void)dismissButtonPressed;

@end

@interface SPAlertView : UIView

@property (nonatomic) NSString *message;
@property (nonatomic, weak) NSObject<SPAlertViewDelegate>* delegate;

@end