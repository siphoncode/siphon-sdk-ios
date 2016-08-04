
@interface SPAppView : UIView

- (instancetype)initWithBundleURL:(NSURL *)url redBox:(BOOL)redBox;
- (instancetype)initWithBundleURL:(NSURL *)url andErrorMessage:(NSString *)errorMessage redBox:(BOOL)redBox;
- (void)cleanUp;

@end