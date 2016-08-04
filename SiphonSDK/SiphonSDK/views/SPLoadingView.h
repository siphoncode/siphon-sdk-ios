
@interface SPLoadingView : UIView

// An array of strings that indicate different stages of progress
@property (nonatomic, weak) NSArray *progression;
// The current stage of progress we're at. When this is set, the progression
// array is inspected and the progress bar is updated accordingly
@property (nonatomic) NSString *progress;

- (instancetype)initWithFrame:(CGRect)frame andProgression:(NSArray *)array;
- (void)reset;
- (void)resetToProgress:(NSString *)progress;
- (void)displayErrorMessage:(NSString *)message
               buttonTarget:(id)target
             buttonSelector:(SEL)buttonPressed;
@end