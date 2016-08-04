
@interface SPBorderedButton : UIButton

@property (nonatomic) BOOL active;

- (void)addBorderTopWithWidth:(float)width andColor:(UIColor *)color;
- (void)addBorderRightWithWidth:(float)width andColor:(UIColor *)color;
- (void)addBorderLeftWithWidth:(float)width andColor:(UIColor *)color;

@end