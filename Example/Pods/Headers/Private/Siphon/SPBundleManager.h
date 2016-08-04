
@protocol SPBundleManagerDelegate

@optional
- (void)bundleManagerIsInitializing;
- (void)bundleIsLoading;
- (void)fetchingAssets:(NSURLSessionDataTask *)fetchingAssetsDataTask;
- (void)fetchedAssets;
@end

@interface SPBundleManager : NSObject

@property (nonatomic, weak) NSObject<SPBundleManagerDelegate>* delegate;
@property (nonatomic) NSURL *bundleURL;

+ (void)createBundleManagerWithAppId:(NSString *)appId andDelegate:(id)delegate forSandbox:(BOOL)forSandbox withDev:(BOOL)dev success:(void (^)(SPBundleManager *))success error:(void (^)(NSError *))error;
+ (void)cleanAppDirectory:(NSString *)appId;

// Instance methods
- (void)loadLocalBundleWithSuccess:(void (^)(NSURL *bundleURL))successCallback andError:(void (^)(NSError *error))errorCallback;
- (void)loadBundleFromURL:(NSURL *)bundlerURL withSuccess:(void (^)(NSURL *bundleURL))successCallback andError:(void (^)(NSError *error))errorCallback;;

@end
