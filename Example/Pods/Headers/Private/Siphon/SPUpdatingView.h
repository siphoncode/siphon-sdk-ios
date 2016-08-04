
@protocol SPUpdatingViewDelegate <NSObject>

- (void)retryButtonPressed;
- (void)cancelButtonPressed;

@end

@interface SPUpdatingView : UIView

@property (nonatomic) NSString *message;
@property (nonatomic) float progress;
@property (nonatomic) BOOL progressVisible;
@property (nonatomic) BOOL retryButtonActive;
@property (nonatomic) BOOL cancelButtonActive;

@property (nonatomic, weak) NSObject<SPUpdatingViewDelegate>* delegate;

- (void)setProgressAnimated:(float)progress;

@end