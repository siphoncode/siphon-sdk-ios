
@interface SPApiClient : NSObject

// Class methods (for unauthenticated requests)
+ (NSURLSessionDataTask *)fetchDataForSubmission:(NSString *)submissionId atHost:(NSString *)host withSuccess:(void (^)(NSDictionary *))successCallback andError:(void (^)(NSError *error))errorCallback;

+ (NSURLSessionDataTask *)fetchAssetsForHashes:(NSDictionary *)hashes from:(NSURL *)url withSuccess:(void (^)(NSData *assetData))successCallback andError:(void (^)(NSError *error))errorCallback;

// Instance methods. Use these for requests requiring authentication.
- (instancetype)initWithAppId:(NSString *)appId andAuthToken:(NSString *)authToken andHost:(NSString *)host;
- (NSURLSessionDataTask *)fetchBundlerURLWithSuccess:(void (^)(NSURL *bundlerURL))successCallback andError:(void (^)(NSError *error))errorCallback;
- (NSURLSessionDataTask *)fetchStreamerURLForConnectionType:(NSString *)connType withSuccess:(void (^)(NSURL *streamerURL))successCallback andError:(void (^)(NSError *error))errorCallback;

@end