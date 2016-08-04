
#import "SPApiClient.h"
#import "SPConstants.h"

#define TICK   NSDate *startTime = [NSDate date]
#define TOCK   NSLog(@"Time: %f", -[startTime timeIntervalSinceNow])

@interface JSON : NSObject

@property (nonatomic) NSDictionary *dictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSString *)stringForKey:(NSString *)key;

@end

@implementation JSON

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        _dictionary = dictionary;
    }
    return self;
}

- (NSString *)stringForKey:(NSString *)key {
    // Takes a json dictionary and returns the value if it exists or an empty
    // string if it doesn't
    
    id item = [self.dictionary objectForKey:key];
    
    if ([item isKindOfClass:[NSString class]] ) {
        return item;
    } else {
        return @"";
    }
}

@end

@interface SPApiClient()

@property (copy, nonatomic) NSString *appId;
@property (copy, nonatomic) NSString *authToken;
@property (copy, nonatomic) NSString *host;
@property (nonatomic) NSString *api;

@end

@implementation SPApiClient

+ (NSURLSessionDataTask *)fetchDataForSubmission:(NSString *)submissionId atHost:(NSString *)host withSuccess:(void (^)(NSDictionary *))successCallback andError:(void (^)(NSError *))errorCallback {
    NSURL *urlExtension = [NSURL URLWithString:[NSString stringWithFormat:@"bundlers/?action=pull&current_submission_id=%@", submissionId]];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@%@", SP_SCHEME, host, SP_API, urlExtension]];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    // Configure the session to accetip JSON response
    sessionConfig.HTTPAdditionalHeaders = @{@"Accept": @"application/json"};
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    
    NSURLSessionDataTask *request = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // Terminate the session (will result in a memory leak otherwise)
        [session invalidateAndCancel];
        if (error) {
            errorCallback(error);
        } else {
            // A response was received. We must now check that it was successful
            NSError *err;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
            // Handle parsing error
            if (err) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Error parsing json.", nil),
                                           NSLocalizedFailureReasonErrorKey: NSLocalizedString(error.localizedFailureReason, nil),
                                           NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Try again later.", nil)
                                           };
                NSError *parseError = [[NSError alloc]
                                       initWithDomain:SP_ERROR_DOMAIN
                                       code:SPApiClientError
                                       userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorCallback(parseError);
                });
            } else if ([jsonDict[@"user_message"] isKindOfClass:[NSString class]] && ![jsonDict[@"user_message"] isEqualToString:@""]){
                NSError *siphonError;
                NSString *errorMessage = jsonDict[@"user_message"];
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(errorMessage, nil),
                                           NSLocalizedFailureReasonErrorKey: NSLocalizedString(errorMessage, nil),
                                           NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"Try again later", nil)};
                siphonError = [[NSError alloc]
                               initWithDomain:SP_ERROR_DOMAIN
                               code:SPApiClientUserError
                               userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorCallback(siphonError);
                });
                
            } else if ([jsonDict[@"submission_id"] isKindOfClass:[NSString class]] && ![jsonDict[@"submission_id"] isEqualToString:@""]) {
                // The request was successful
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback(jsonDict);
                });
            } else {
                NSError *siphonError;
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Unexpected error.", nil),
                                           NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"An unexpected error occurred.", nil),
                                           NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"Try again later", nil)};
                siphonError = [[NSError alloc]
                               initWithDomain:SP_ERROR_DOMAIN
                               code:SPApiClientError
                               userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorCallback(siphonError);
                });
            }
            
        }
        
    }];
    
    [request resume];
    return request;
}

- (instancetype)initWithAppId:(NSString *)appId andAuthToken:(NSString *)authToken andHost:(NSString *)host {
    if (self = [super init]) {
        _appId = appId;
        _authToken = authToken;
        _host = host;
        _api = [NSString stringWithFormat:@"%@://%@%@", SP_SCHEME, host, SP_API];
    }
    return self;
}

- (NSURLSessionDataTask *)fetchBundlerURLWithSuccess:(void (^)(NSURL *))successCallback andError:(void (^)(NSError *))errorCallback {
    NSString *urlExtension = [NSString stringWithFormat:@"bundlers/?app_id=%@&base_version=%@&action=pull&platform=%@", self.appId, SP_BASE_VERSION, SP_PLATFORM];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.api, urlExtension]];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration
                                                defaultSessionConfiguration];
    
    // Configure the session to accept JSON response
    sessionConfig.HTTPAdditionalHeaders = @{@"Accept": @"application/json", @"X-Siphon-Token": self.authToken};
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    
    // This makes a GET request to the given URL
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // Note that NSURLSessionDataTask considers any response from the
        // server a success
        [session invalidateAndCancel];
        if (error) {
            // A connection error of some description occurred
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey:
                                           NSLocalizedString(@"Failed to connect.", nil),
                                       NSLocalizedFailureReasonErrorKey:
                                           NSLocalizedString(error.localizedFailureReason, nil),
                                       NSLocalizedRecoverySuggestionErrorKey:
                                           NSLocalizedString(@"Make sure you are connected to the internet.", nil)
                                       };
            NSError *connectionError = [[NSError alloc]
                                        initWithDomain:SP_ERROR_DOMAIN
                                        code:SPApiClientError
                                        userInfo:userInfo];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                errorCallback(connectionError);
            });
            
        } else {
            // The server responded with an http response of some type
            // Parse the received json
            NSError *err;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
            
            JSON *json = [[JSON alloc] initWithDictionary:jsonDict];
            
            // Handle parsing error
            if (err) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey:
                                               NSLocalizedString(@"Error retrieving app.", nil),
                                           NSLocalizedFailureReasonErrorKey:
                                               NSLocalizedString(error.localizedFailureReason, nil),
                                           NSLocalizedRecoverySuggestionErrorKey:
                                               NSLocalizedString(@"Please try again later.", nil)
                                           };
                NSError *parseError = [[NSError alloc]
                                       initWithDomain:SP_ERROR_DOMAIN
                                       code:SPApiClientError
                                       userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorCallback(parseError);
                });
                return;
            }
            
            NSURL *bundler_url = [[NSURL alloc] initWithString:[json stringForKey:@"bundler_url"]];
            NSString *errorType = [json stringForKey:@"error_type"];
            NSString *errorMsg = [json stringForKey:@"message"];
            NSDictionary *userInfo;
            NSError *siphonError;
            
            if (bundler_url.path) {
                // The request was successful, and the data was parsed
                // successfully. Enjoy your URL and have a nice day.
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback(bundler_url);
                });
                return;
            } else if ([errorType isEqualToString:@"app_binary_outdated"]) {
                userInfo = @{
                             NSLocalizedDescriptionKey:
                                 NSLocalizedString(@"App binary outdated.", nil),
                             NSLocalizedFailureReasonErrorKey:
                                 NSLocalizedString(@"App binary outdated.",
                                                   nil),
                             NSLocalizedRecoverySuggestionErrorKey:
                                 NSLocalizedString(@"Please download the latest version from the App Store.", nil)
                             };
                
                siphonError = [[NSError alloc]
                               initWithDomain:SP_ERROR_DOMAIN
                               code:SPApiClientError
                               userInfo:userInfo];
                
            } else if ([errorType isEqualToString:@"app_binary_too_new"]) {
                NSString *errString = [NSString
                                       stringWithFormat:@"Please edit the file called 'Siphonfile' in your app directory to base_version %@ in order to continue.", SP_BASE_VERSION];
                userInfo = @{
                             NSLocalizedDescriptionKey:
                                 NSLocalizedString(@"App binary too new.", nil),
                             NSLocalizedFailureReasonErrorKey:
                                 NSLocalizedString(@"Siphon Sandbox is using a newer version of React Native than your app supports.",
                                                   nil),
                             NSLocalizedRecoverySuggestionErrorKey:
                                 NSLocalizedString(errString, nil)
                             };
                siphonError = [[NSError alloc]
                               initWithDomain:SP_ERROR_DOMAIN
                               code:SPApiClientError
                               userInfo:userInfo];
            } else {
                
                userInfo = @{
                             NSLocalizedDescriptionKey:
                                 NSLocalizedString(@"Unexpected error.", nil),
                             NSLocalizedFailureReasonErrorKey:
                                 NSLocalizedString(@"An unexpected error occurred.",
                                                   nil),
                             NSLocalizedRecoverySuggestionErrorKey:
                                 NSLocalizedString(errorMsg, nil)
                             };
                siphonError = [[NSError alloc]
                               initWithDomain:SP_ERROR_DOMAIN
                               code:SPApiClientError
                               userInfo:userInfo];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                errorCallback(siphonError);
            });
        }
        
    }];
    [dataTask resume];
    return dataTask;
}

- (NSURLSessionDataTask *)fetchStreamerURLForConnectionType:(NSString *)connType withSuccess:(void (^)(NSURL *))successCallback andError:(void (^)(NSError *))errorCallback {
    NSString *urlExtension = [NSString stringWithFormat:
                              @"streamers/?app_id=%@&type=%@", self.appId, connType];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.api, urlExtension]];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration
                                                defaultSessionConfiguration];
    // Configure the session to accept JSON response
    sessionConfig.HTTPAdditionalHeaders = @{@"Accept": @"application/json", @"X-Siphon-Token": self.authToken};
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // Note that NSURLSessionDataTask considers any response from the
        // server a success
        [session invalidateAndCancel];
        if (error) {
            // A connection error of some description occurred
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey:
                                           NSLocalizedString(@"Failed to connect.", nil),
                                       NSLocalizedFailureReasonErrorKey:
                                           NSLocalizedString(error.localizedFailureReason, nil),
                                       NSLocalizedRecoverySuggestionErrorKey:
                                           NSLocalizedString(@"Make sure you are connected to the internet.", nil)
                                       };
            NSError *connectionError = [[NSError alloc]
                                        initWithDomain:SP_ERROR_DOMAIN
                                        code:SPApiClientError
                                        userInfo:userInfo];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                errorCallback(connectionError);
            });
            
        } else {
            // The server responded with an http response of some type
            // Parse the received json
            NSError *err;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
            
            JSON *json = [[JSON alloc] initWithDictionary:jsonDict];
            
            // Handle parsing error
            if (err) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey:
                                               NSLocalizedString(@"Error retrieving app.", nil),
                                           NSLocalizedFailureReasonErrorKey:
                                               NSLocalizedString(error.localizedFailureReason, nil),
                                           NSLocalizedRecoverySuggestionErrorKey:
                                               NSLocalizedString(@"Please try again later.", nil)
                                           };
                NSError *parseError = [[NSError alloc]
                                       initWithDomain:SP_ERROR_DOMAIN
                                       code:SPApiClientError
                                       userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorCallback(parseError);
                });
                return;
            }
            
            NSURL *streamerUrl = [[NSURL alloc] initWithString:[json stringForKey:@"streamer_url"]];
            
            if (streamerUrl) {
                // Success
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback(streamerUrl);
                });
                
            } else {
                // An unexpected error occurred
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey:
                                               NSLocalizedString(@"Error connecting to streamer.", nil),
                                           NSLocalizedFailureReasonErrorKey:
                                               NSLocalizedString(@"Error connecting to streamer.", nil),
                                           NSLocalizedRecoverySuggestionErrorKey:
                                               NSLocalizedString(@"Please try again later.", nil)
                                           };
                NSError *requestError = [[NSError alloc]
                                         initWithDomain:SP_ERROR_DOMAIN
                                         code:SPApiClientError
                                         userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorCallback(requestError);
                });
            }
        }
        
    }];
    [dataTask resume];
    return dataTask;
}

+ (NSURLSessionDataTask *)fetchAssetsForHashes:(NSDictionary *)hashes from:(NSURL *)url withSuccess:(void (^)(NSData *))successCallback andError:(void (^)(NSError *))errorCallback {
    NSData *postData = [NSJSONSerialization dataWithJSONObject:hashes
                                                       options:NSJSONWritingPrettyPrinted error:nil];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postData;
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request
                                                    completionHandler:^(NSData *data,
                                                                        NSURLResponse *response,
                                                                        NSError *error)
      {
          [session invalidateAndCancel];
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
          NSInteger statusCode = httpResponse.statusCode;
          // NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          if (error) {
              // A connection error of some description occurred
              NSDictionary *userInfo = @{
                                         NSLocalizedDescriptionKey:
                                             NSLocalizedString(@"Failed to connect.", nil),
                                         NSLocalizedFailureReasonErrorKey:
                                             NSLocalizedString(error.localizedFailureReason, nil),
                                         NSLocalizedRecoverySuggestionErrorKey:
                                             NSLocalizedString(@"Make sure you are connected to the internet.", nil)
                                         };
              NSError *connectionError = [[NSError alloc]
                                          initWithDomain:SP_ERROR_DOMAIN
                                          code:SPApiClientError
                                          userInfo:userInfo];
              dispatch_async(dispatch_get_main_queue(), ^{
                  errorCallback(connectionError);
              });
              
          } else if (statusCode < 200 || statusCode > 299) {
              // The server responded with an http response indicating an error
              NSDictionary *userInfo = @{
                                         NSLocalizedDescriptionKey:
                                             NSLocalizedString(@"Error retrieving app.", nil),
                                         NSLocalizedFailureReasonErrorKey:
                                             NSLocalizedString(error.localizedFailureReason, nil),
                                         NSLocalizedRecoverySuggestionErrorKey:
                                             NSLocalizedString(@"Please try again later.", nil)
                                         };
              NSError *requestError = [[NSError alloc]
                                       initWithDomain:SP_ERROR_DOMAIN
                                       code:SPApiClientError
                                       userInfo:userInfo];
              
              dispatch_async(dispatch_get_main_queue(), ^{
                  errorCallback(requestError);
              });
              
          } else {
              // Call the success callback            
              dispatch_async(dispatch_get_main_queue(), ^{
                  successCallback(data);
              });
          }
          
      }];
    
    [postDataTask resume];
    return postDataTask;
}

@end